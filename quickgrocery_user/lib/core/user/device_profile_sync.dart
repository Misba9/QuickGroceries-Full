import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/firestore/firestore_retry.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';

/// Collects platform / version / device metadata and merge-writes it onto
/// `customers/{uid}` + `users/{uid}` without ever clearing existing values.
abstract final class DeviceProfileSync {
  static const _prefFingerprint = 'device_profile_fingerprint_v1';
  static const _prefLastSeenMs = 'device_profile_last_seen_ms_v1';

  /// Minimum gap between lastSeen-only writes when device fingerprint is unchanged.
  static const _lastSeenMinInterval = Duration(minutes: 15);

  static DeviceProfileSnapshot? _cachedSnapshot;
  static Future<void>? _inFlight;
  static String? _lastUidSynced;

  /// Clear write cache on logout so the next account always syncs.
  static Future<void> clearLocalCache() async {
    _inFlight = null;
    _lastUidSynced = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefFingerprint);
      await prefs.remove(_prefLastSeenMs);
    } catch (_) {}
  }

  /// Detect platform / version / device once per process (cached).
  static Future<DeviceProfileSnapshot> detect() async {
    final cached = _cachedSnapshot;
    if (cached != null) return cached;

    final package = await PackageInfo.fromPlatform();
    final appVersion = package.version.trim();
    final buildNumber = package.buildNumber.trim();

    var platform = _platformLabel();
    var deviceModel = '';
    var osVersion = '';

    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await plugin.webBrowserInfo;
        platform = 'Web';
        deviceModel = (web.browserName.name).trim();
        osVersion = (web.userAgent ?? '').trim();
        if (osVersion.length > 120) {
          osVersion = osVersion.substring(0, 120);
        }
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final a = await plugin.androidInfo;
            platform = 'Android';
            deviceModel = [
              a.brand,
              a.model,
            ].where((s) => s.trim().isNotEmpty).join(' ').trim();
            osVersion = 'Android ${a.version.release}'.trim();
          case TargetPlatform.iOS:
            final i = await plugin.iosInfo;
            platform = 'iOS';
            deviceModel = (i.utsname.machine.isNotEmpty
                    ? i.utsname.machine
                    : i.model)
                .trim();
            osVersion = '${i.systemName} ${i.systemVersion}'.trim();
          case TargetPlatform.macOS:
            final m = await plugin.macOsInfo;
            platform = 'macOS';
            deviceModel = m.model.trim();
            osVersion = m.osRelease.trim();
          case TargetPlatform.windows:
            final w = await plugin.windowsInfo;
            platform = 'Windows';
            deviceModel = w.computerName.trim();
            osVersion = w.displayVersion.trim();
          case TargetPlatform.linux:
            final l = await plugin.linuxInfo;
            platform = 'Linux';
            deviceModel = (l.prettyName.trim().isNotEmpty
                    ? l.prettyName
                    : l.name)
                .trim();
            osVersion = (l.version ?? '').trim();
          case TargetPlatform.fuchsia:
            platform = 'Fuchsia';
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DeviceProfileSync] device_info: $e');
    }

    final snap = DeviceProfileSnapshot(
      platform: platform,
      appVersion: appVersion,
      buildNumber: buildNumber,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
    _cachedSnapshot = snap;
    return snap;
  }

  static String _platformLabel() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  /// Sync after app startup / resume. Skips duplicate fingerprint writes.
  static Future<void> syncAfterStartup() =>
      sync(reason: DeviceProfileSyncReason.startup);

  /// Sync on login / OTP success.
  static Future<void> syncAfterLogin() =>
      sync(reason: DeviceProfileSyncReason.login);

  /// Sync on registration profile save.
  static Future<void> syncAfterRegistration() =>
      sync(reason: DeviceProfileSyncReason.registration);

  /// Sync when FCM token is refreshed / persisted.
  static Future<void> syncOnTokenRefresh() =>
      sync(reason: DeviceProfileSyncReason.tokenRefresh);

  static Future<void> sync({
    required DeviceProfileSyncReason reason,
    String? uid,
  }) async {
    final userId = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return;

    // Collapse concurrent syncs for the same user.
    if (_inFlight != null && _lastUidSynced == userId) {
      return _inFlight;
    }
    _lastUidSynced = userId;
    final future = _syncBody(userId: userId, reason: reason);
    _inFlight = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  static Future<void> _syncBody({
    required String userId,
    required DeviceProfileSyncReason reason,
  }) async {
    try {
      final snap = await detect();
      final prefs = await SharedPreferences.getInstance();
      final fingerprint = snap.fingerprint;
      final prevFingerprint = prefs.getString(_prefFingerprint) ?? '';
      final lastSeenMs = prefs.getInt(_prefLastSeenMs) ?? 0;
      final now = DateTime.now();
      final sinceLastSeen = Duration(
        milliseconds: now.millisecondsSinceEpoch - lastSeenMs,
      );

      final deviceChanged = fingerprint != prevFingerprint;
      final isLogin = reason == DeviceProfileSyncReason.login ||
          reason == DeviceProfileSyncReason.registration;
      final forceSeen = isLogin ||
          reason == DeviceProfileSyncReason.tokenRefresh ||
          sinceLastSeen >= _lastSeenMinInterval;

      if (!deviceChanged && !forceSeen) {
        return;
      }

      final payload = <String, dynamic>{
        'uid': userId,
        'updated_at': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'last_seen': FieldValue.serverTimestamp(),
        'last_active_at': FieldValue.serverTimestamp(),
      };

      if (isLogin) {
        payload['lastLogin'] = FieldValue.serverTimestamp();
        payload['last_login'] = FieldValue.serverTimestamp();
      }

      // Device fields only when changed (or first sync / login / token).
      // Never write empty / null (preserves existing Firestore values).
      if (deviceChanged || isLogin || reason == DeviceProfileSyncReason.tokenRefresh) {
        void put(String key, String value) {
          final v = value.trim();
          if (v.isNotEmpty) payload[key] = v;
        }

        put('platform', snap.platform);
        put('fcmPlatform', snap.platform);
        put('device_type', snap.platform);
        put('appVersion', snap.appVersion);
        put('app_version', snap.displayVersion);
        put('buildNumber', snap.buildNumber);
        put('build_number', snap.buildNumber);
        put('deviceModel', snap.deviceModel);
        put('device_model', snap.deviceModel);
        put('osVersion', snap.osVersion);
        put('os_version', snap.osVersion);
      }

      await withFirestoreRetry(() async {
        final batch = FirebaseFirestore.instance.batch();
        final customer = FirebaseFirestore.instance
            .collection(UserProfileRepository.customers)
            .doc(userId);
        final users = FirebaseFirestore.instance
            .collection(UserProfileRepository.users)
            .doc(userId);
        batch.set(customer, payload, SetOptions(merge: true));
        batch.set(users, payload, SetOptions(merge: true));
        await batch.commit();
      });

      await prefs.setString(_prefFingerprint, fingerprint);
      await prefs.setInt(_prefLastSeenMs, now.millisecondsSinceEpoch);

      if (kDebugMode) {
        debugPrint(
          '[DeviceProfileSync] ${reason.name} '
          'platform=${snap.platform} version=${snap.displayVersion} '
          'deviceChanged=$deviceChanged',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DeviceProfileSync] failed: $e');
    }
  }
}

enum DeviceProfileSyncReason {
  startup,
  login,
  registration,
  tokenRefresh,
}

class DeviceProfileSnapshot {
  const DeviceProfileSnapshot({
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.deviceModel,
    required this.osVersion,
  });

  final String platform;
  final String appVersion;
  final String buildNumber;
  final String deviceModel;
  final String osVersion;

  String get displayVersion {
    if (appVersion.isEmpty) return buildNumber;
    if (buildNumber.isEmpty) return appVersion;
    return '$appVersion+$buildNumber';
  }

  String get fingerprint =>
      '$platform|$appVersion|$buildNumber|$deviceModel|$osVersion';
}
