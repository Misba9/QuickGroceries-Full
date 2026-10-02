import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/navigation/home_tab_observer.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';

/// Tracks which user-app screens are opened and writes events for the admin
/// App Heatmap page (`app_screen_views`).
abstract final class AppHeatmapTracker {
  static const collection = 'app_screen_views';

  static bool _started = false;
  static String? _activeScreen;
  static DateTime? _enteredAt;
  static String? _lastLoggedKey;
  static DateTime? _lastLoggedAt;

  static const _tabLabels = <String>[
    'home',
    'categories',
    'offers',
    'ai_chat',
    'profile',
  ];

  static void start() {
    if (_started) return;
    _started = true;
    appRouteObserver.topRouteListenable.addListener(_onNavChange);
    HomeTabObserver.selectedIndexListenable.addListener(_onNavChange);
    _onNavChange();
  }

  static void stop() {
    if (!_started) return;
    _started = false;
    appRouteObserver.topRouteListenable.removeListener(_onNavChange);
    HomeTabObserver.selectedIndexListenable.removeListener(_onNavChange);
    _flushDwell();
  }

  static void _onNavChange() {
    final next = _resolveScreen();
    if (next == null || next == _activeScreen) return;
    _flushDwell();
    _activeScreen = next;
    _enteredAt = DateTime.now();
    unawaited(_logView(next));
  }

  static String? _resolveScreen() {
    final route = appRouteObserver.topRouteName;
    if (route != null &&
        route.isNotEmpty &&
        route != AppRoutes.home &&
        route != AppRoutes.splash) {
      return 'route:$route';
    }
    // Home shell / unnamed root → bottom tab.
    final tab = HomeTabObserver.selectedIndexListenable.value;
    if (tab < 0 || tab >= _tabLabels.length) return 'tab:home';
    return 'tab:${_tabLabels[tab]}';
  }

  static void _flushDwell() {
    final screen = _activeScreen;
    final entered = _enteredAt;
    if (screen == null || entered == null) return;
    final dwellMs = DateTime.now().difference(entered).inMilliseconds;
    if (dwellMs < 800) return;
    unawaited(_logView(screen, dwellMs: dwellMs, isDwell: true));
  }

  static Future<void> _logView(
    String screen, {
    int dwellMs = 0,
    bool isDwell = false,
  }) async {
    final now = DateTime.now();
    final dedupeKey = '$screen|${isDwell ? 'dwell' : 'view'}';
    if (!isDwell &&
        _lastLoggedKey == dedupeKey &&
        _lastLoggedAt != null &&
        now.difference(_lastLoggedAt!) < const Duration(seconds: 4)) {
      return;
    }
    _lastLoggedKey = dedupeKey;
    _lastLoggedAt = now;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    var userName = (user?.displayName ?? '').trim();
    var userPhone = (user?.phoneNumber ?? '').trim();
    try {
      final profile = await UserProfileCache.readProfile();
      if (userName.isEmpty) userName = (profile['name'] ?? '').trim();
      if (userPhone.isEmpty) userPhone = (profile['phone'] ?? '').trim();
    } catch (_) {}

    String appVersion = '';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (_) {}

    final parts = screen.split(':');
    final kind = parts.isNotEmpty ? parts.first : 'unknown';
    final name = parts.length > 1 ? parts.sublist(1).join(':') : screen;

    final payload = <String, dynamic>{
      'screen': screen,
      'screenKind': kind,
      'screenName': name,
      'event': isDwell ? 'dwell' : 'view',
      'dwellMs': dwellMs,
      'userId': uid,
      'userName': userName,
      'userPhone': userPhone,
      'platform': defaultTargetPlatform.name,
      'appVersion': appVersion,
      'hour': now.hour,
      'weekday': now.weekday, // 1=Mon … 7=Sun
      'createdAt': FieldValue.serverTimestamp(),
      'clientAt': Timestamp.fromDate(now.toUtc()),
    };

    try {
      await FirebaseFirestore.instance.collection(collection).add(payload);
      // Lightweight aggregate for snappy admin heat cells.
      await FirebaseFirestore.instance
          .collection('app_screen_stats')
          .doc(screen.replaceAll('/', '_'))
          .set(
        {
          'screen': screen,
          'screenKind': kind,
          'screenName': name,
          'views': FieldValue.increment(isDwell ? 0 : 1),
          'dwellEvents': FieldValue.increment(isDwell ? 1 : 0),
          'totalDwellMs': FieldValue.increment(dwellMs),
          'lastSeenAt': FieldValue.serverTimestamp(),
          'platforms': FieldValue.arrayUnion([defaultTargetPlatform.name]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AppHeatmap] log failed: $e');
    }
  }
}
