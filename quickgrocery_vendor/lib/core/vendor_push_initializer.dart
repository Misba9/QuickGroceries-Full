import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'vendor_notification_hub.dart';

/// FCM display for vendor app.
///
/// Server sends **data-only** ops pushes (`displayMode=data_only`). This module
/// is the sole tray display path — never combine with FCM `notification` payloads.
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
    if (kDebugMode) debugPrint('[VendorNotify] push initializer ready');
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
      '[VendorNotify] $stage '
      'source=$source '
      'listenerId=${listenerId ?? "—"} '
      'messageId=${msg.messageId ?? "—"} '
      'eventId=${d['eventId'] ?? "—"} '
      'type=${d['type'] ?? "—"} '
      'orderId=${d['orderId'] ?? "—"} '
      'displayMode=${d['displayMode'] ?? "—"}',
    );
  }

  static Future<void> handleForegroundMessage(
    RemoteMessage msg, {
    String listenerId = 'main_onMessage',
  }) async {
    _log('DEVICE RECEIVED', msg, source: 'fcm_foreground', listenerId: listenerId);

    final data = Map<String, dynamic>.from(msg.data);
    await VendorNotificationHub.instance.handleFcmPayload(data);

    if (!_isDataOnlyRemote(msg)) {
      _log(
        'SKIP LOCAL SHOW — not data_only (legacy payload or pre-deploy server)',
        msg,
        source: 'fcm_foreground',
        listenerId: listenerId,
      );
      return;
    }

    await showFromRemoteMessage(msg);
    _log('LOCAL SHOW', msg, source: 'fcm_foreground', listenerId: listenerId);
  }

  static Future<void> handleBackgroundMessage(
    RemoteMessage msg, {
    String listenerId = 'background_handler',
  }) async {
    _log('DEVICE RECEIVED', msg, source: 'fcm_background', listenerId: listenerId);

    if (!_isDataOnlyRemote(msg)) {
      _log(
        'SKIP LOCAL SHOW — not data_only (legacy payload or pre-deploy server)',
        msg,
        source: 'fcm_background',
        listenerId: listenerId,
      );
      return;
    }

    await showFromRemoteMessage(msg);
    _log('LOCAL SHOW', msg, source: 'fcm_background', listenerId: listenerId);
  }

  static Future<void> showFromRemoteMessage(RemoteMessage msg) async {
    if (kIsWeb || !_initialized) return;

    final data = msg.data;
    final title = data['title']?.toString() ?? '🛒 New Order';
    final body =
        data['message']?.toString() ?? data['body']?.toString() ?? '';

    final payload = jsonEncode(Map<String, dynamic>.from(data));
    final eventId = data['eventId']?.toString() ?? msg.messageId ?? '';
    final id = eventId.hashCode & 0x7fffffff;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Vendor order alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: const RawResourceAndroidNotificationSound('new_order'),
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
