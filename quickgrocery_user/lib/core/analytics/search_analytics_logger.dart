import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';

/// Writes user product-search events to Firestore for the admin Search Analytics page.
abstract final class SearchAnalyticsLogger {
  static const collection = 'search_logs';

  static String? _lastDedupeKey;
  static DateTime? _lastDedupeAt;

  /// Logs a search. [force] bypasses the short dedupe window (use for submit/voice/chip).
  static Future<void> log({
    required String query,
    required int resultCount,
    required String source,
    List<String> topResultIds = const [],
    List<String> topResultNames = const [],
    int catalogSampleSize = 0,
    bool force = false,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;

    final normalized =
        trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final dedupeKey = '${uid.isEmpty ? 'guest' : uid}|$normalized|$source';
    final now = DateTime.now();
    if (!force &&
        _lastDedupeKey == dedupeKey &&
        _lastDedupeAt != null &&
        now.difference(_lastDedupeAt!) < const Duration(seconds: 15)) {
      return;
    }
    _lastDedupeKey = dedupeKey;
    _lastDedupeAt = now;

    String appVersion = '';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (_) {}

    var userName = (user?.displayName ?? '').trim();
    var userPhone = (user?.phoneNumber ?? '').trim();
    var userEmail = (user?.email ?? '').trim();
    try {
      final profile = await UserProfileCache.readProfile();
      if (userName.isEmpty) userName = (profile['name'] ?? '').trim();
      if (userPhone.isEmpty) userPhone = (profile['phone'] ?? '').trim();
      if (userEmail.isEmpty) userEmail = (profile['email'] ?? '').trim();
    } catch (_) {}

    final platform = defaultTargetPlatform.name;
    final payload = <String, dynamic>{
      'query': trimmed,
      'queryNormalized': normalized,
      'userId': uid,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'resultCount': resultCount,
      'hasResults': resultCount > 0,
      'source': source,
      'platform': platform,
      'appVersion': appVersion,
      'catalogSampleSize': catalogSampleSize,
      'topResultIds': topResultIds.take(5).toList(growable: false),
      'topResultNames': topResultNames.take(5).toList(growable: false),
      'createdAt': FieldValue.serverTimestamp(),
      'clientAt': Timestamp.fromDate(now.toUtc()),
    };

    try {
      await FirebaseFirestore.instance.collection(collection).add(payload);
    } catch (e) {
      if (kDebugMode) debugPrint('[SearchAnalytics] log failed: $e');
    }
  }
}
