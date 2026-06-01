import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/vendor_auth_errors.dart';
import 'vendor_push_initializer.dart';

/// Vendor push: topic subscription + device token storage.
class VendorFcmBootstrap {
  VendorFcmBootstrap._();

  static const _deviceIdKey = 'vendor_device_id';

  static Future<void> configureForVendor(String vendorId) async {
    if (kIsWeb || vendorId.isEmpty) return;
    try {
      await VendorPushInitializer.ensureInitialized();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
      );

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await messaging.getToken();
      if (token == null) {
        VendorAuthErrors.logDebug('[VendorFCM] token is null');
        return;
      }

      final topic = _vendorTopic(vendorId);
      await messaging.subscribeToTopic(topic);
      VendorAuthErrors.logDebug('[VendorFCM] token saved topic=$topic');
      if (kDebugMode) {
        debugPrint('[VendorNotify] FCM token registered vendor=$vendorId');
      }

      await _saveToken(vendorId, token, topic);

      messaging.onTokenRefresh.listen((t) async {
        VendorAuthErrors.logDebug('[VendorFCM] token refreshed');
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
      final deviceId = await _deviceId();
      final vendorRef =
          FirebaseFirestore.instance.collection('vendors').doc(vendorId);

      await vendorRef.set(
        {
          'fcmToken': token,
          'fcm_token': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
          'fcmTopics': FieldValue.arrayUnion([topic]),
        },
        SetOptions(merge: true),
      );

      await vendorRef.collection('deviceTokens').doc(deviceId).set(
        {
          'token': token,
          'deviceId': deviceId,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        debugPrint('[VendorNotify] deviceTokens/$deviceId saved');
      }
    } catch (e) {
      VendorAuthErrors.logDebug('[VendorFCM] token write failed: $e');
    }
  }

  static Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  static String _vendorTopic(String vendorId) {
    final s = vendorId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\-_.~%]'), '_');
    return 'vendor_${s.isEmpty ? "unknown" : s}';
  }
}
