import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'push_message_dedupe.dart';
import 'vendor_notification_hub.dart';

/// FCM foreground/background display + permissions (mobile only).
class VendorPushInitializer {
  VendorPushInitializer._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const _channelId = 'vendor_orders';
  static const _channelName = 'Vendor Orders';

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
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'New orders and order updates',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('new_order'),
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }

    _initialized = true;
    if (kDebugMode) {
      debugPrint('[VendorNotify] push initializer ready');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final p = response.payload;
    if (p == null || p.isEmpty) return;
    try {
      final map = jsonDecode(p) as Map<String, dynamic>;
      VendorNotificationHub.instance.handleFcmPayload(map);
    } catch (_) {
      /* ignore */
    }
  }

  static Future<void> handleForegroundMessage(RemoteMessage msg) async {
    if (!PushMessageDedupe.markIfNew(msg, appTag: 'VendorNotify')) return;

    if (kDebugMode) {
      debugPrint(
        '[VendorNotify] FCM foreground messageId=${msg.messageId} '
        'title=${msg.notification?.title} data=${msg.data}',
      );
    }

    final data = Map<String, dynamic>.from(msg.data);
    final type = data['type']?.toString() ?? '';

    if (type == 'new_order') {
      await VendorNotificationHub.instance.handleFcmPayload(data);
      if (kDebugMode) {
        debugPrint('[VendorNotify] foreground new_order → in-app only');
      }
      return;
    }

    if (type == 'order_cancelled') {
      await VendorNotificationHub.instance.handleFcmPayload(data);
      if (_shouldShowLocalTray(msg, foreground: true)) {
        await showFromRemoteMessage(msg);
      }
      if (kDebugMode) {
        debugPrint('[VendorNotify] foreground order_cancelled');
      }
      return;
    }

    if (_shouldShowLocalTray(msg, foreground: true)) {
      await showFromRemoteMessage(msg);
    }
    await VendorNotificationHub.instance.handleFcmPayload(data);
  }

  /// Background handler entry — skip when FCM notification payload is shown by OS.
  static Future<void> handleBackgroundMessage(RemoteMessage msg) async {
    if (!PushMessageDedupe.markIfNew(msg, appTag: 'VendorNotify')) return;
    if (!_shouldShowLocalTray(msg, foreground: false)) {
      if (kDebugMode) {
        debugPrint(
          '[VendorNotify] background skip local show — OS handles notification payload',
        );
      }
      return;
    }
    await showFromRemoteMessage(msg);
  }

  static bool _shouldShowLocalTray(RemoteMessage msg, {required bool foreground}) {
    if (msg.notification == null) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS auto-presents FCM notification payloads in foreground and background.
      return false;
    }
    // Android shows notification payload in background/killed; not in foreground.
    return foreground;
  }

  static Future<void> showFromRemoteMessage(RemoteMessage msg) async {
    if (kIsWeb || !_initialized) return;

    final n = msg.notification;
    final data = msg.data;
    final title =
        n?.title ?? data['title']?.toString() ?? '🛒 New Order';
    final body = n?.body ??
        data['message']?.toString() ??
        data['body']?.toString() ??
        '';

    final payload = jsonEncode(Map<String, dynamic>.from(data));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Vendor order alerts',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: const RawResourceAndroidNotificationSound('new_order'),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final orderId = data['orderId']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final id = orderId.isNotEmpty
        ? '$type:$orderId'.hashCode
        : (msg.messageId?.hashCode ?? msg.hashCode);
    await _plugin.show(id & 0x7fffffff, title, body, details, payload: payload);
    if (kDebugMode) {
      debugPrint('[VendorNotify] local notification id=$id title=$title');
    }
  }
}
