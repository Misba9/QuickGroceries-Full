import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Vendor push: subscribe to `vendor_{vendorId}` for order/stock alerts.
class VendorFcmBootstrap {
  VendorFcmBootstrap._();

  static Future<void> configureForVendor(String vendorId) async {
    if (kIsWeb || vendorId.isEmpty) return;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token == null) return;
    final topic = _vendorTopic(vendorId);
    await messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      debugPrint('[VendorFCM] token=$token topic=$topic');
    }
    await FirebaseFirestore.instance.collection('vendors').doc(vendorId).set(
      {
        'fcmToken': token,
        'fcm_token': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
        'fcmTopics': FieldValue.arrayUnion([topic]),
      },
      SetOptions(merge: true),
    );
    messaging.onTokenRefresh.listen((t) async {
      await FirebaseFirestore.instance.collection('vendors').doc(vendorId).set(
        {'fcmToken': t, 'fcm_token': t},
        SetOptions(merge: true),
      );
    });
  }

  static String _vendorTopic(String vendorId) {
    final s = vendorId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-_.~%]'), '_');
    return 'vendor_${s.isEmpty ? "unknown" : s}';
  }
}
