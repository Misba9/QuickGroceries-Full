import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Rider push — data-only FCM from Cloud Functions is the sole tray display path.
class DeliveryPushInitializer {
  DeliveryPushInitializer._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _alertPlayer = AudioPlayer();

  static bool _initialized = false;
  static bool _listenersAttached = false;
  static DateTime? _lastFcmAlertAt;

  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

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

  static void attachMessagingListeners() {
    if (_listenersAttached || kIsWeb) return;
    _listenersAttached = true;

    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      await handleForegroundMessage(message, listenerId: 'main_onMessage');
    });

    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _dispatchFromMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      _dispatchFromMessage(message);
    });

    if (kDebugMode) {
      debugPrint('[DeliveryNotify] LISTENER CREATED main_onMessage');
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
      '[DeliveryNotify] $stage '
      'source=$source '
      'listenerId=${listenerId ?? "—"} '
      'messageId=${msg.messageId ?? "—"} '
      'eventId=${d['eventId'] ?? "—"} '
      'type=${d['type'] ?? "—"} '
      'orderId=${d['orderId'] ?? "—"}',
    );
  }

  static Future<void> handleBackgroundMessage(
    RemoteMessage msg, {
    String listenerId = 'background_handler',
  }) async {
    _log('DEVICE RECEIVED', msg, source: 'fcm_background', listenerId: listenerId);

    if (!_isDataOnlyRemote(msg)) {
      _log('SKIP LOCAL SHOW — not data_only', msg, source: 'fcm_background');
      return;
    }

    await showFromRemoteMessage(msg);
    _log('LOCAL SHOW', msg, source: 'fcm_background', listenerId: listenerId);
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

  static Future<void> handleForegroundMessage(
    RemoteMessage msg, {
    String listenerId = 'default',
  }) async {
    _log('DEVICE RECEIVED', msg, source: 'fcm_foreground', listenerId: listenerId);

    final data = Map<String, dynamic>.from(msg.data);
    final type = data['type']?.toString() ?? '';

    if (type == 'order_cancelled') {
      _markFcmAlertHandled();
      await playCancellationAlert();
      onCancellationPush?.call(data);
    } else if (type == 'delivery_assigned' || type == 'driver_assigned') {
      _markFcmAlertHandled();
      await playAssignmentAlert();
      onAssignmentPush?.call(data);
    }

    if (!_isDataOnlyRemote(msg)) {
      _log('SKIP LOCAL SHOW — not data_only', msg, source: 'fcm_foreground');
      return;
    }

    await showFromRemoteMessage(msg);
    _log('LOCAL SHOW', msg, source: 'fcm_foreground', listenerId: listenerId);
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

    final data = msg.data;
    final title = data['title']?.toString() ?? 'Delivery Update';
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
          channelDescription: 'Delivery alerts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: const RawResourceAndroidNotificationSound('delivery_alert'),
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
