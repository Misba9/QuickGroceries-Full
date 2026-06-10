import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Delivery rider push: `delivery_{riderId}` + persist token on profile.
class DeliveryFcmBootstrap {
  DeliveryFcmBootstrap._();

  static Future<void> configureForRider(String riderId) async {
    if (kIsWeb || riderId.isEmpty) return;
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
    await messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      debugPrint('[DeliveryFCM] token=$token topic=$topic');
    }
    await FirebaseFirestore.instance.collection('delivery_boys').doc(riderId).set(
      {
        'fcmToken': token,
        'fcm_token': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    messaging.onTokenRefresh.listen((t) async {
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
