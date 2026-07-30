import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'push_message_dedupe.dart';
import 'delivery_notification_router.dart';

/// Rider push — data-only FCM from Cloud Functions is the sole tray display path.
///
/// Guarantees:
/// - [ensureInitialized] / [attachMessagingListeners] run at most once
/// - one local [show] per logical event (dedupe by eventId / messageId)
/// - never pairs OS tray (`notification` payload) with flutter_local_notifications
class DeliveryPushInitializer {
  DeliveryPushInitializer._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _alertPlayer = AudioPlayer();

  static bool _initialized = false;
  static bool _listenersAttached = false;
  static bool _channelReady = false;
  static Future<void>? _initFuture;
  static DateTime? _lastFcmAlertAt;
  static String? _cachedToken;

  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  static void Function(Map<String, dynamic> data)? onAssignmentPush;
  static void Function(Map<String, dynamic> data)? onCancellationPush;

  static const _channelId = 'delivery_assignments';
  static const _channelName = 'Delivery Assignments';

  static Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  static Future<void> _doInit() async {
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

    await _ensureAndroidChannel();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }

    try {
      _cachedToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      /* ignore */
    }

    _initialized = true;

    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final p = launch!.notificationResponse?.payload;
        if (p != null && p.isNotEmpty) {
          final map = jsonDecode(p) as Map<String, dynamic>;
          DeliveryNotificationRouter.enqueue(map);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeliveryNotify] launch details skipped: $e');
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[DeliveryNotify] init complete once '
        'token=${_cachedToken ?? "—"} '
        'time=${DateTime.now().toIso8601String()}',
      );
    }
  }

  static Future<void> _ensureAndroidChannel() async {
    if (_channelReady || kIsWeb) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      _channelReady = true;
      return;
    }
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
    _channelReady = true;
  }

  /// Attach FCM stream listeners exactly once for the process lifetime.
  static void attachMessagingListeners() {
    if (_listenersAttached || kIsWeb) return;
    _listenersAttached = true;

    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      await handleForegroundMessage(message, listenerId: 'main_onMessage');
    });

    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      DeliveryNotificationRouter.handleNotificationOpen(
        Map<String, dynamic>.from(message.data),
      );
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      DeliveryNotificationRouter.enqueue(
        Map<String, dynamic>.from(message.data),
      );
    });

    if (kDebugMode) {
      debugPrint('[DeliveryNotify] LISTENER CREATED main_onMessage (once)');
    }
  }

  static bool _isDataOnlyRemote(RemoteMessage msg) {
    return msg.data['displayMode']?.toString().toLowerCase() == 'data_only';
  }

  /// True when FCM included a system tray notification block (OS will/did show).
  static bool _hasSystemNotificationPayload(RemoteMessage msg) {
    return msg.notification != null;
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
      'orderId=${d['orderId'] ?? "—"} '
      'displayMode=${d['displayMode'] ?? "—"} '
      'hasNotificationPayload=${msg.notification != null} '
      'token=${_cachedToken ?? "—"} '
      'time=${DateTime.now().toIso8601String()}',
    );
  }

  static Future<bool> _claimMessage(
    RemoteMessage msg, {
    required String source,
    required String listenerId,
  }) async {
    final isNew = await PushMessageDedupe.markIfNew(
      msg,
      appTag: 'DeliveryNotify',
      source: source,
      listenerId: listenerId,
      deviceToken: _cachedToken,
    );
    if (!isNew) {
      _log('SKIP DUPLICATE EVENT', msg, source: source, listenerId: listenerId);
    }
    return isNew;
  }

  static Future<void> handleBackgroundMessage(
    RemoteMessage msg, {
    String listenerId = 'background_handler',
  }) async {
    _log('DEVICE RECEIVED', msg, source: 'fcm_background', listenerId: listenerId);

    if (!await _claimMessage(
      msg,
      source: 'fcm_background',
      listenerId: listenerId,
    )) {
      return;
    }

    // Never pair OS tray + flutter_local_notifications for the same event.
    if (_hasSystemNotificationPayload(msg)) {
      _log(
        'SKIP LOCAL SHOW — FCM notification payload present (OS tray)',
        msg,
        source: 'fcm_background',
        listenerId: listenerId,
      );
      return;
    }

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

  static void _onNotificationTap(NotificationResponse response) {
    final p = response.payload;
    if (p == null || p.isEmpty) return;
    try {
      final map = jsonDecode(p) as Map<String, dynamic>;
      DeliveryNotificationRouter.handleNotificationOpen(map);
    } catch (_) {
      /* ignore */
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
    String listenerId = 'main_onMessage',
  }) async {
    _log('DEVICE RECEIVED', msg, source: 'fcm_foreground', listenerId: listenerId);

    if (!await _claimMessage(
      msg,
      source: 'fcm_foreground',
      listenerId: listenerId,
    )) {
      return;
    }

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

    if (_hasSystemNotificationPayload(msg)) {
      _log(
        'SKIP LOCAL SHOW — FCM notification payload present (OS tray)',
        msg,
        source: 'fcm_foreground',
        listenerId: listenerId,
      );
      return;
    }

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
    if (kIsWeb) return;
    await ensureInitialized();
    if (!_initialized) return;

    final data = msg.data;
    final title = data['title']?.toString() ?? 'Delivery Update';
    final body =
        data['message']?.toString() ?? data['body']?.toString() ?? '';

    final payload = jsonEncode(Map<String, dynamic>.from(data));
    final eventId = data['eventId']?.toString().trim().isNotEmpty == true
        ? data['eventId']!.toString()
        : (msg.messageId ?? '');
    // Stable Android id+tag so a second show of the same event replaces, never stacks.
    final id = eventId.isNotEmpty
        ? eventId.hashCode & 0x7fffffff
        : (msg.messageId?.hashCode ??
                '${data['orderId']}:${data['type']}'.hashCode) &
            0x7fffffff;

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
