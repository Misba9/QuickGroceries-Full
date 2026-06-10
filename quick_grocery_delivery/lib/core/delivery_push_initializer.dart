import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'push_message_dedupe.dart';

/// Rider push: foreground sound + system notification for assignments/cancellations.
class DeliveryPushInitializer {
  DeliveryPushInitializer._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _alertPlayer = AudioPlayer();

  static bool _initialized = false;
  static bool _listenersAttached = false;
  static DateTime? _lastFcmAlertAt;

  static void Function(Map<String, dynamic> data)? onAssignmentPush;
  static void Function(Map<String, dynamic> data)? onCancellationPush;

  static const _channelId = 'delivery_assignments';
  static const _channelName = 'Delivery Assignments';

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
          description: 'Delivery assignment and cancellation alerts',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('delivery_alert'),
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
  }

  /// Register FCM listeners once at app start (not per screen).
  static void attachMessagingListeners() {
    if (_listenersAttached || kIsWeb) return;
    _listenersAttached = true;

    FirebaseMessaging.onMessage.listen((message) async {
      await handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _dispatchFromMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      _dispatchFromMessage(message);
    });

    if (kDebugMode) {
      debugPrint('[DeliveryNotify] FCM listeners attached');
    }
  }

  static void _dispatchFromMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final type = data['type']?.toString() ?? '';
    if (type == 'order_cancelled') {
      onCancellationPush?.call(data);
      return;
    }
    onAssignmentPush?.call(data);
  }

  static void _onNotificationTap(NotificationResponse response) {
    final p = response.payload;
    if (p == null || p.isEmpty) return;
    try {
      final map = jsonDecode(p) as Map<String, dynamic>;
      _dispatch(map);
    } catch (_) {
      /* ignore */
    }
  }

  static void _dispatch(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type == 'order_cancelled') {
      onCancellationPush?.call(data);
    } else {
      onAssignmentPush?.call(data);
    }
  }

  static bool get recentlyHandledByFcm {
    final at = _lastFcmAlertAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(seconds: 8);
  }

  static void _markFcmAlertHandled() {
    _lastFcmAlertAt = DateTime.now();
  }

  static Future<void> handleForegroundMessage(RemoteMessage msg) async {
    if (!PushMessageDedupe.markIfNew(msg, appTag: 'DeliveryNotify')) return;

    if (kDebugMode) {
      debugPrint(
        '[DeliveryNotify] FCM foreground messageId=${msg.messageId} '
        'type=${msg.data['type']}',
      );
    }

    final data = Map<String, dynamic>.from(msg.data);
    final type = data['type']?.toString() ?? '';

    if (type == 'order_cancelled') {
      _markFcmAlertHandled();
      await playCancellationAlert();
      onCancellationPush?.call(data);
      if (_shouldShowLocalTray(msg, foreground: true)) {
        await showFromRemoteMessage(msg);
      }
      return;
    }

    if (type == 'delivery_assigned' || type == 'driver_assigned') {
      _markFcmAlertHandled();
      await playAssignmentAlert();
      onAssignmentPush?.call(data);
      if (_shouldShowLocalTray(msg, foreground: true)) {
        await showFromRemoteMessage(msg);
      }
      return;
    }

    if (_shouldShowLocalTray(msg, foreground: true)) {
      await showFromRemoteMessage(msg);
    }
  }

  static bool _shouldShowLocalTray(RemoteMessage msg, {required bool foreground}) {
    if (msg.notification == null) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) return false;
    return foreground;
  }

  static Future<void> playAssignmentAlert() async {
    try {
      HapticFeedback.heavyImpact();
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sound/alert.mp3'));
    } catch (e) {
      if (kDebugMode) debugPrint('[DeliveryPush] alert $e');
    }
  }

  static Future<void> playCancellationAlert() async {
    try {
      HapticFeedback.heavyImpact();
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource('sound/alert.mp3'));
    } catch (e) {
      if (kDebugMode) debugPrint('[DeliveryPush] cancel alert $e');
    }
  }

  static Future<void> showFromRemoteMessage(RemoteMessage msg) async {
    if (kIsWeb || !_initialized) return;

    final n = msg.notification;
    final data = msg.data;
    final title = n?.title ?? data['title']?.toString() ?? 'Delivery Update';
    final body = n?.body ??
        data['message']?.toString() ??
        data['body']?.toString() ??
        '';

    final payload = jsonEncode(Map<String, dynamic>.from(data));

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Delivery alerts',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: const RawResourceAndroidNotificationSound('delivery_alert'),
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
  }
}
