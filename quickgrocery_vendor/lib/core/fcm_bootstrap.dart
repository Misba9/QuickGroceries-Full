import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth/vendor_auth_errors.dart';

/// Vendor push: subscribe to `vendor_{vendorId}` for order/stock alerts.
class VendorFcmBootstrap {
  VendorFcmBootstrap._();

  static Future<void> configureForVendor(String vendorId) async {
    if (kIsWeb || vendorId.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null) return;
      final topic = _vendorTopic(vendorId);
      await messaging.subscribeToTopic(topic);
      VendorAuthErrors.logDebug('[VendorFCM] token set topic=$topic');
      await _saveToken(vendorId, token, topic);
      messaging.onTokenRefresh.listen((t) async {
        await _saveToken(vendorId, t, topic);
      });
    } catch (e) {
      VendorAuthErrors.logDebug('[VendorFCM] configure skipped: $e');
    }
  }

  static Future<void> _saveToken(
    String vendorId,
    String token,
    String topic,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .set(
        {
          'fcmToken': token,
          'fcm_token': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
          'fcmTopics': FieldValue.arrayUnion([topic]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      VendorAuthErrors.logDebug('[VendorFCM] token write failed: $e');
    }
  }

  static String _vendorTopic(String vendorId) {
    final s = vendorId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\-_.~%]'), '_');
    return 'vendor_${s.isEmpty ? "unknown" : s}';
  }
}
