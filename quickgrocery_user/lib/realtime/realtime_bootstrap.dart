import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }

  void _attachFcm() {
    // Foreground push → in-app banner. The OS won't show a tray
    // notification while the app is in the foreground; users still
    // need to know.
    _onMessageSub = FirebaseMessaging.onMessage.listen((msg) {
      if (!mounted) return;
      final n = msg.notification;
      if (n == null) return;
      _showInAppSnack(n.title ?? 'Update', n.body ?? '');
    });

    // Tap on a tray notification → deep link via `data.deepLink`.
    // Cloud Functions should set `data: { deepLink: '/orders/123' }`.
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final link = msg.data['deepLink'];
      if (link is String && link.isNotEmpty) {
        debugPrint('[Realtime] FCM tap deepLink=$link');
        // Navigation hooked at the app router level.
      }
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
      // Persist initial token on sign-in so server can address us.
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await _persistFcmToken(token);
      } catch (e) {
        if (kDebugMode) debugPrint('[Realtime] FCM token fetch failed: $e');
      }
    });
  }

  Future<void> _persistFcmToken(String token) async {
    final uid = _lastUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('customers').doc(uid).set(
        {
          'fcmToken': token,
          'fcmPlatform': defaultTargetPlatform.name,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Realtime] FCM token write failed: $e');
    }
  }

  void _showInAppSnack(String title, String body) {
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
