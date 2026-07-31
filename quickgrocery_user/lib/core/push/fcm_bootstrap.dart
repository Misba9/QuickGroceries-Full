import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';

/// One-time FCM setup split across frames (plugin/token vs topics).
class FcmBootstrap {
  FcmBootstrap._();

  static bool _pluginReady = false;
  static bool _topicsSubscribed = false;

  static const defaultTopics = <String>[
    'all_users',
    'offers',
    'vegetables',
    'dairy',
    'premium_users',
  ];

  /// Frame +20: plugin + presentation + token. No topic burst.
  static Future<void> configurePluginAndTokenOnly() async {
    if (kIsWeb || _pluginReady) return;
    _pluginReady = true;

    await FcmPushInitializer.ensureInitialized();
    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _waitForApnsToken(messaging);
    }

    unawaited(() async {
      try {
        await messaging.getToken();
      } catch (_) {}
    }());
  }

  /// Full configure (plugin + topics). Prefer split APIs after Home.
  static Future<void> configure() async {
    await configurePluginAndTokenOnly();
    await subscribeDefaultTopics();
  }

  /// Frame +22: one topic per frame.
  static Future<void> subscribeDefaultTopics([
    FirebaseMessaging? messaging,
  ]) async {
    if (kIsWeb) return;
    if (_topicsSubscribed) return;
    _topicsSubscribed = true;
    await configurePluginAndTokenOnly();
    final m = messaging ?? FirebaseMessaging.instance;

    var ok = 0;
    for (final topic in defaultTopics) {
      try {
        await m.subscribeToTopic(topic);
        ok++;
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] subscribe $topic failed: $e');
      }
      final gate = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!gate.isCompleted) gate.complete();
      });
      SchedulerBinding.instance.scheduleFrame();
      await gate.future;
    }
    if (kDebugMode) {
      debugPrint('[FCM] topics ready ($ok/${defaultTopics.length})');
    }
  }

  static Future<void> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}
