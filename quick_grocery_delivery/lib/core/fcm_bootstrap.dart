import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delivery rider push: `delivery_{riderId}` + persist token on profile.
class DeliveryFcmBootstrap {
  DeliveryFcmBootstrap._();

  static const _subscribedTopicKey = 'delivery_fcm_subscribed_topic';

  static String? _configuredRiderId;
  static StreamSubscription<String>? _tokenRefreshSub;

  static Future<void> configureForRider(String riderId) async {
    if (kIsWeb || riderId.isEmpty) return;
    if (_configuredRiderId == riderId && _tokenRefreshSub != null) {
      if (kDebugMode) {
        debugPrint('[DeliveryFCM] already configured rider=$riderId');
      }
      return;
    }

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
    if (subscribed != topic) {
      await messaging.subscribeToTopic(topic);
      await prefs.setString(_subscribedTopicKey, topic);
      if (kDebugMode) {
        debugPrint('[DeliveryNotify] FCM topic subscribed topic=$topic');
      }
    }
    await FirebaseFirestore.instance.collection('delivery_boys').doc(riderId).set(
      {
        'fcmToken': token,
        'fcm_token': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _tokenRefreshSub = messaging.onTokenRefresh.listen((t) async {
      await FirebaseFirestore.instance.collection('delivery_boys').doc(riderId).set(
        {'fcmToken': t, 'fcm_token': t},
        SetOptions(merge: true),
      );
    });
  }

  static String _deliveryTopic(String riderId) {
    final s = riderId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-_.~%]'), '_');
    return 'delivery_${s.isEmpty ? "unknown" : s}';
  }
}
