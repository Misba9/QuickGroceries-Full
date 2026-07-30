import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'push_message_dedupe.dart';
import 'vendor_notification_hub.dart';
import 'vendor_notification_router.dart';

/// FCM display for vendor app.
///
/// Server must send **data-only** ops pushes (`displayMode=data_only`, no
/// `notification` block). This module is the sole tray display path — never
/// combine with an FCM `notification` payload (that causes two tray entries).
class VendorPushInitializer {
  VendorPushInitializer._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _listenersAttached = false;

  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

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

    // Cold start from local tray (data-only FCM) — not available via getInitialMessage.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final p = launch!.notificationResponse?.payload;
        if (p != null && p.isNotEmpty) {
          final map = jsonDecode(p) as Map<String, dynamic>;
          VendorNotificationRouter.enqueue(map);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VendorNotify] launch details skipped: $e');
      }
    }

    if (kDebugMode) debugPrint('[VendorNotify] push initializer ready');
  }

  /// Attach FCM stream listeners exactly once for the process lifetime.
  static Future<void> attachMessagingListeners() async {
    if (_listenersAttached || kIsWeb) return;
    _listenersAttached = true;

    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();

    _onMessageSub = FirebaseMessaging.onMessage.listen((msg) async {
      await handleForegroundMessage(msg, listenerId: 'main_onMessage');
    });

    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      if (kDebugMode) {
        debugPrint(
          '[VendorNotify] notification opened app '
          'type=${msg.data['type']} orderId=${msg.data['orderId']}',
        );
      }
      await VendorNotificationRouter.handleNotificationOpen(
        Map<String, dynamic>.from(msg.data),
      );
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      if (kDebugMode) {
        debugPrint(
          '[VendorNotify] cold start from FCM '
          'type=${initial.data['type']} orderId=${initial.data['orderId']}',
        );
      }
      VendorNotificationRouter.enqueue(
        Map<String, dynamic>.from(initial.data),
      );
    }

    if (kDebugMode) {
      debugPrint('[VendorNotify] LISTENER CREATED main_onMessage (once)');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final p = response.payload;
    if (p == null || p.isEmpty) return;
    try {
      final map = jsonDecode(p) as Map<String, dynamic>;
      VendorNotificationRouter.handleNotificationOpen(map);
    } catch (_) {
      /* ignore */
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
      '[VendorNotify] $stage '
      'source=$source '
      'listenerId=${listenerId ?? "—"} '
      'messageId=${msg.messageId ?? "—"} '
      'eventId=${d['eventId'] ?? "—"} '
      'type=${d['type'] ?? "—"} '
      'orderId=${d['orderId'] ?? "—"} '
      'displayMode=${d['displayMode'] ?? "—"} '
      'hasNotificationPayload=${msg.notification != null}',
    );
  }

  /// Returns false when this FCM event was already handled (suppress duplicate tray).
  static Future<bool> _claimMessage(
    RemoteMessage msg, {
    required String source,
    required String listenerId,
  }) async {
    final isNew = await PushMessageDedupe.markIfNew(
      msg,
      appTag: 'VendorNotify',
      source: source,
      listenerId: listenerId,
    );
    if (!isNew) {
      _log('SKIP DUPLICATE EVENT', msg, source: source, listenerId: listenerId);
    }
    return isNew;
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
    await VendorNotificationHub.instance.handleFcmPayload(data);

    // Never pair OS tray + flutter_local_notifications for the same event.
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

  static Future<void> showFromRemoteMessage(RemoteMessage msg) async {
    if (kIsWeb || !_initialized) return;

    final data = msg.data;
    final title = data['title']?.toString() ?? '🛒 New Order';
    final body =
        data['message']?.toString() ?? data['body']?.toString() ?? '';

    final payload = jsonEncode(Map<String, dynamic>.from(data));
    final eventId = data['eventId']?.toString() ?? msg.messageId ?? '';
    // Stable Android id+tag so a second show of the same event replaces, never stacks.
    final id = eventId.isNotEmpty
        ? eventId.hashCode & 0x7fffffff
        : (msg.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) &
            0x7fffffff;

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
