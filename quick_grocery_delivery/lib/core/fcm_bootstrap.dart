import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delivery rider push: `delivery_{riderId}` + persist a single token on profile.
class DeliveryFcmBootstrap {
  DeliveryFcmBootstrap._();

  static const _subscribedTopicKey = 'delivery_fcm_subscribed_topic';

  static String? _configuredRiderId;
  static StreamSubscription<String>? _tokenRefreshSub;
  static Future<void>? _configureFuture;

  static Future<void> configureForRider(String riderId) async {
    if (kIsWeb || riderId.isEmpty) return;
    if (_configuredRiderId == riderId && _tokenRefreshSub != null) {
      if (kDebugMode) {
        debugPrint('[DeliveryFCM] already configured rider=$riderId');
      }
      return;
    }

    // Serialize concurrent configure calls (login + main + auth restore).
    final previous = _configureFuture;
    final gate = Completer<void>();
    _configureFuture = gate.future;
    if (previous != null) {
      try {
        await previous;
      } catch (_) {
        /* continue */
      }
    }

    try {
      await _configureUnlocked(riderId);
    } finally {
      gate.complete();
    }
  }

  static Future<void> _configureUnlocked(String riderId) async {
    if (_configuredRiderId == riderId && _tokenRefreshSub != null) return;

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _configuredRiderId = riderId;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );
    final token = await messaging.getToken();
    if (token == null) return;

    final topic = _deliveryTopic(riderId);
    final prefs = await SharedPreferences.getInstance();
    final subscribed = prefs.getString(_subscribedTopicKey);

    // Unsubscribe previous topic so one device is not fan'd by stale topics.
    if (subscribed != null &&
        subscribed.isNotEmpty &&
        subscribed != topic) {
      try {
        await messaging.unsubscribeFromTopic(subscribed);
        if (kDebugMode) {
          debugPrint(
            '[DeliveryNotify] FCM topic unsubscribed topic=$subscribed',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DeliveryNotify] unsubscribe failed: $e');
        }
      }
    }

    if (subscribed != topic) {
      await messaging.subscribeToTopic(topic);
      await prefs.setString(_subscribedTopicKey, topic);
      if (kDebugMode) {
        debugPrint('[DeliveryNotify] FCM topic subscribed topic=$topic');
      }
    }

    // Single canonical token field (+ legacy alias for older readers).
    await FirebaseFirestore.instance.collection('delivery_boys').doc(riderId).set(
      {
        'fcmToken': token,
        'fcm_token': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (kDebugMode) {
      debugPrint(
        '[DeliveryNotify] token registered rider=$riderId '
        'token=$token time=${DateTime.now().toIso8601String()}',
      );
    }

    _tokenRefreshSub = messaging.onTokenRefresh.listen((t) async {
      await FirebaseFirestore.instance.collection('delivery_boys').doc(riderId).set(
        {
          'fcmToken': t,
          'fcm_token': t,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (kDebugMode) {
        debugPrint('[DeliveryNotify] token refreshed rider=$riderId token=$t');
      }
    });
  }

  /// Call on logout so this device stops receiving the rider topic.
  static Future<void> clearForLogout() async {
    if (kIsWeb) return;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    final riderId = _configuredRiderId;
    _configuredRiderId = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final topic = prefs.getString(_subscribedTopicKey);
      if (topic != null && topic.isNotEmpty) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        await prefs.remove(_subscribedTopicKey);
        if (kDebugMode) {
          debugPrint('[DeliveryNotify] logout unsubscribed topic=$topic');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeliveryNotify] clearForLogout: $e');
      }
    }

    // Clear stored tokens so backend token-path (if any) cannot dual-target us.
    if (riderId != null && riderId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('delivery_boys').doc(riderId).set(
          {
            'fcmToken': FieldValue.delete(),
            'fcm_token': FieldValue.delete(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {
        /* ignore */
      }
    }
  }

  static String _deliveryTopic(String riderId) {
    final s = riderId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\-_.~%]'), '_');
    return 'delivery_${s.isEmpty ? "unknown" : s}';
  }
}
