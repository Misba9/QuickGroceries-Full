import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/firestore/firestore_retry.dart';
import 'package:quickgrocery/core/push/fcm_bootstrap.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/startup/post_home_startup.dart';

/// Configures FCM foreground bridge so the realtime layer behaves correctly
/// across reconnects, kill/restart, and OS-level notifications.
///
/// Firestore persistence is configured once in [FirebaseStartupGate].
/// FCM listeners and token persistence wait until [PostHomeStartup.homeVisible].
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
  String? _lastUid;
  bool _fcmAttached = false;

  @override
  void initState() {
    super.initState();
    // Firestore settings already applied once in [FirebaseStartupGate].

    // Cold-start notification payload — after FCM plugin (+20), one frame later.
    PostHomeStartup.onFrame(21, () {
      unawaited(() async {
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (initial != null) {
          await _persistInboxFromMessage(initial);
          enqueuePushNavigation(initial.data);
        }
      }());
    });

    // Attach FCM listeners at frame +20 (with plugin/token schedule).
    PostHomeStartup.onFrame(20, _attachFcmLayer);
  }

  void _attachFcmLayer() {
    if (_fcmAttached) return;
    _fcmAttached = true;
    _attachFcm();
    // One-shot token persist — ongoing auth changes use [authUserProvider]
    // via [ref.listen] (no second FirebaseAuth.authStateChanges subscription).
    final user = FirebaseAuth.instance.currentUser;
    _lastUid = user?.uid;
    if (user != null) {
      unawaited(_persistTokenForCurrentUser());
    }
  }

  Future<void> _persistTokenForCurrentUser() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _persistFcmToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] token fetch failed: $e');
    }
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

    _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      _persistFcmToken,
    );
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
    final message = body.isNotEmpty ? '$title\n$body' : title;
    if (navigationData == null || navigationData.isEmpty) {
      AppSnackBar.info(message, context: context);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          onPressed: () => handlePushNavigation(navigationData),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Single auth subscription via [authUserProvider] (shared with shell).
    ref.listen(authUserProvider, (prev, next) {
      if (!_fcmAttached) return;
      final user = resolveAuthUser(next);
      final uid = user?.uid;
      if (uid == _lastUid) return;
      _lastUid = uid;
      if (user == null) return;
      if (kDebugMode) debugPrint('[FCM] auth token persist uid=$uid');
      unawaited(_persistTokenForCurrentUser());
    });

    return widget.child;
  }
}
