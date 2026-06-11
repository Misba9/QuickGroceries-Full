import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quickgrocery/core/permissions/app_permission_coordinator.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';

/// Data-only FCM from Cloud Functions is the sole tray display path for ops pushes.
class FcmPushInitializer {
  FcmPushInitializer._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    await _plugin.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      const channels = <AndroidNotificationChannel>[
        AndroidNotificationChannel(
          'quickgrocery_default',
          'General',
          description: 'Marketing and general updates',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          'quickgrocery_orders',
          'Orders',
          description: 'Order updates',
          importance: Importance.max,
        ),
        AndroidNotificationChannel(
          'quickgrocery_offers',
          'Offers',
          description: 'Deals and promotions',
          importance: Importance.high,
        ),
        AndroidNotificationChannel(
          'quickgrocery_delivery',
          'Delivery',
          description: 'Delivery tracking',
          importance: Importance.high,
        ),
      ];
      for (final c in channels) {
        await android.createNotificationChannel(c);
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (!await AppPermissionCoordinator.notificationAlreadyAsked()) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await AppPermissionCoordinator.requestAndroidNotificationOnce();
    }

    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    final p = response.payload;
    if (p == null || p.isEmpty) return;
    try {
      final map = jsonDecode(p) as Map<String, dynamic>;
      handlePushNavigation(map);
    } catch (_) {
      /* ignore */
    }
  }

  static String _androidChannelId(RemoteMessage msg) {
    switch (msg.data['soundType']?.toString() ?? '') {
      case 'orders':
        return 'quickgrocery_orders';
      case 'offers':
        return 'quickgrocery_offers';
      case 'delivery':
        return 'quickgrocery_delivery';
      default:
        return 'quickgrocery_default';
    }
  }

  static String _channelTitle(String id) {
    switch (id) {
      case 'quickgrocery_orders':
        return 'Orders';
      case 'quickgrocery_offers':
        return 'Offers';
      case 'quickgrocery_delivery':
        return 'Delivery';
      default:
        return 'Quick Grocery';
    }
  }

  static bool _isDataOnlyRemote(RemoteMessage msg) {
    return msg.data['displayMode']?.toString().toLowerCase() == 'data_only';
  }

  static void _log(
    String stage,
    RemoteMessage msg, {
    required String source,
    String? listenerId,
  }) {
    if (!kDebugMode) return;
    final d = msg.data;
    debugPrint(
      '[UserNotify] $stage '
      'source=$source '
      'listenerId=${listenerId ?? "—"} '
      'messageId=${msg.messageId ?? "—"} '
      'eventId=${d['eventId'] ?? "—"} '
      'type=${d['type'] ?? "—"}',
    );
  }

  static Future<void> handleRemoteMessage(
    RemoteMessage msg, {
    required String source,
    String listenerId = 'default',
  }) async {
    if (kIsWeb) return;

    _log('DEVICE RECEIVED', msg, source: source, listenerId: listenerId);

    if (!_isDataOnlyRemote(msg)) {
      _log('SKIP LOCAL SHOW — not data_only', msg, source: source);
      return;
    }

    await _showLocalTray(msg);
    _log('LOCAL SHOW', msg, source: source, listenerId: listenerId);
  }

  static Future<void> _showLocalTray(RemoteMessage msg) async {
    if (kIsWeb || !_initialized) return;
    final data = msg.data;
    final title = data['title']?.toString() ?? 'Quick Grocery';
    final body = data['message']?.toString() ?? data['body']?.toString() ?? '';
    final payload = jsonEncode({
      'redirectType': data['redirectType']?.toString() ?? '',
      'deepLink': data['deepLink']?.toString() ?? '',
      'logId': data['logId']?.toString() ?? '',
    });

    final channelId = _androidChannelId(msg);
    final eventId = data['eventId']?.toString() ?? msg.messageId ?? '';
    final id = eventId.hashCode & 0x7fffffff;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelTitle(channelId),
          channelDescription: 'FCM push',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          tag: eventId.isNotEmpty ? eventId : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
