import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/core/firestore/firestore_retry.dart';
import 'package:quickgrocery/core/push/fcm_bootstrap.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';

/// Configures Firestore offline persistence + FCM foreground bridge so
/// the realtime layer behaves correctly across reconnects, kill/restart,
/// and OS-level notifications.
///
/// **Place this near the top of the widget tree**, inside `ProviderScope`
/// and outside any auth gate (so we can persist the FCM token under
/// `customers/{uid}` as soon as the user signs in).
class RealtimeBootstrap extends ConsumerStatefulWidget {
  const RealtimeBootstrap({super.key, required this.child});

  final Widget child;

  /// Run-once Firestore settings — call **before** any Firestore read.
  /// Idempotent; safe to call multiple times in tests.
  static bool _firestoreConfigured = false;
  static void configureFirestore() {
    if (_firestoreConfigured) return;
    _firestoreConfigured = true;
    if (kIsWeb) {
      // Web requires `enablePersistence(...)` at runtime instead.
      return;
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  @override
  ConsumerState<RealtimeBootstrap> createState() => _RealtimeBootstrapState();
}

class _RealtimeBootstrapState extends ConsumerState<RealtimeBootstrap> {
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<User?>? _onAuthSub;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    RealtimeBootstrap.configureFirestore();
    _attachFcm();
    _attachAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        await _persistInboxFromMessage(initial);
        enqueuePushNavigation(initial.data);
      }
    });
  }

  Future<void> _persistInboxFromMessage(RemoteMessage msg) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final n = msg.notification;
    final d = msg.data;
    try {
      await withFirestoreRetry(
        () => FirebaseFirestore.instance
            .collection('customers')
            .doc(uid)
            .collection('notification_inbox')
            .add({
          'title': n?.title ?? '',
          'body': n?.body ?? '',
          'redirectType': d['redirectType']?.toString() ?? '',
          'deepLink': d['deepLink']?.toString() ?? '',
          'imageUrl': d['imageUrl']?.toString() ?? '',
          'logId': d['logId']?.toString() ?? '',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        }),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] inbox write failed: $e');
    }
  }

  void _attachFcm() {
    _onMessageSub = FirebaseMessaging.onMessage.listen((msg) async {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[UserNotify] LISTENER CREATED realtime_bootstrap_onMessage',
        );
      }
      await _persistInboxFromMessage(msg);
      final data = msg.data;
      final title = data['title']?.toString() ?? msg.notification?.title ?? 'Update';
      final body = data['message']?.toString() ?? msg.notification?.body ?? '';
      if (kIsWeb) {
        _showInAppSnack(title, body);
      } else {
        await FcmPushInitializer.handleRemoteMessage(
          msg,
          source: 'fcm_foreground',
          listenerId: 'realtime_bootstrap',
        );
        if (title.isNotEmpty) {
          _showInAppSnack(title, body, navigationData: Map<String, dynamic>.from(data));
        }
      }
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'notification_received',
          parameters: {
            'foreground': 'true',
            'has_notification': (msg.notification != null).toString(),
          },
        );
      } catch (_) {
        /* optional */
      }
    });

    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      await _persistInboxFromMessage(msg);
      await handlePushNavigation(msg.data);
    });

    // Token refresh → write into the customer doc the user is signed
    // into right now. Other apps query `customers/*.fcmToken` to fan
    // out targeted pushes.
    _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      _persistFcmToken,
    );
  }

  void _attachAuth() {
    _onAuthSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      _lastUid = user?.uid;
      if (user == null) return;
      await UserProfileRepository().hydrateLocal(user.uid);
      // Persist initial token on sign-in so server can address us.
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          if (kDebugMode) debugPrint('[FCM] auth token persist uid=${user.uid}');
          await _persistFcmToken(token);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] token fetch failed: $e');
      }
    });
  }

  Future<void> _persistFcmToken(String token) async {
    final uid = _lastUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await withFirestoreRetry(
        () => FirebaseFirestore.instance.collection('customers').doc(uid).set(
          {
            'fcmToken': token,
            'fcm_token': token,
            'fcmPlatform': defaultTargetPlatform.name,
            'fcmUpdatedAt': FieldValue.serverTimestamp(),
            'fcmTopics': FieldValue.arrayUnion(FcmBootstrap.defaultTopics),
          },
          SetOptions(merge: true),
        ),
      );
      await FcmBootstrap.subscribeDefaultTopics();
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] token write failed: $e');
    }
  }

  void _showInAppSnack(
    String title,
    String body, {
    Map<String, dynamic>? navigationData,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(body),
            ],
          ],
        ),
        action: navigationData != null
            ? SnackBarAction(
                label: 'View',
                onPressed: () => handlePushNavigation(navigationData),
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _onAuthSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
