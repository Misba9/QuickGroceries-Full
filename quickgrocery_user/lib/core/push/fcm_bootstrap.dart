import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:quickgrocery/core/permissions/app_permission_coordinator.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';

/// One-time FCM setup: permissions, token, topic subscription, debug logs.
///
/// Topic broadcast (`all_users`) works without Firestore login — subscribe here
/// on cold start, not only after auth.
class FcmBootstrap {
  FcmBootstrap._();

  static bool _configured = false;

  /// Must match admin default topic and [RealtimeBootstrap] topics.
  static const defaultTopics = <String>[
    'all_users',
    'offers',
    'vegetables',
    'dairy',
    'premium_users',
  ];

  /// Call once after [Firebase.initializeApp] in `main.dart`.
  static Future<void> configure() async {
    if (kIsWeb || _configured) return;
    _configured = true;

    await FcmPushInitializer.ensureInitialized();

    final messaging = FirebaseMessaging.instance;

    await AppPermissionCoordinator.requestNotificationPermissionOnce();

    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _waitForApnsToken(messaging);
    }

    final token = await messaging.getToken();
    if (token != null) {
      _log('FCM token (copy for Firebase Console test): $token');
    } else {
      _log('FCM token is null — check Google Play services / iOS APNs setup');
    }

    await subscribeDefaultTopics(messaging);

    messaging.onTokenRefresh.listen((newToken) {
      _log('token refreshed: $newToken');
    });
  }

  /// Idempotent — safe to call after login as well.
  static Future<void> subscribeDefaultTopics([
    FirebaseMessaging? messaging,
  ]) async {
    if (kIsWeb) return;
    final m = messaging ?? FirebaseMessaging.instance;
    for (final topic in defaultTopics) {
      try {
        await m.subscribeToTopic(topic);
        _log('subscribed to topic: $topic');
      } catch (e, st) {
        _log('subscribe $topic failed: $e');
        if (kDebugMode) debugPrintStack(stackTrace: st);
      }
    }
  }

  static Future<void> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 12; attempt++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null) {
        _log('APNs token ready (length=${apns.length})');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    _log(
      'APNs token still null — use a physical iPhone with Push capability '
      'and upload APNs key in Firebase Console',
    );
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FCM] $message');
    }
  }
}
