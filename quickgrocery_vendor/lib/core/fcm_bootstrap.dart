import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/vendor_auth_errors.dart';
import 'vendor_push_initializer.dart';

/// Vendor push: single topic subscription + unique device token storage.
class VendorFcmBootstrap {
  VendorFcmBootstrap._();

  static const _deviceIdKey = 'vendor_device_id';
  static const _subscribedTopicKey = 'vendor_fcm_subscribed_topic';

  static String? _configuredVendorId;
  static StreamSubscription<String>? _tokenRefreshSub;

  static Future<void> configureForVendor(String vendorId) async {
    if (kIsWeb || vendorId.isEmpty) return;
    if (_configuredVendorId == vendorId && _tokenRefreshSub != null) {
      if (kDebugMode) {
        debugPrint('[VendorNotify] FCM already configured vendor=$vendorId');
      }
      return;
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _configuredVendorId = vendorId;

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
        // alert:false — tray comes only from flutter_local_notifications.
        await messaging.setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );
      }

      final token = await messaging.getToken();
      if (token == null) {
        VendorAuthErrors.logDebug('[VendorFCM] token is null');
        return;
      }

      final topic = _vendorTopic(vendorId);
      final prefs = await SharedPreferences.getInstance();
      final previousTopic = prefs.getString(_subscribedTopicKey);
      if (previousTopic != null &&
          previousTopic.isNotEmpty &&
          previousTopic != topic) {
        try {
          await messaging.unsubscribeFromTopic(previousTopic);
          if (kDebugMode) {
            debugPrint(
              '[VendorNotify] FCM unsubscribed old topic=$previousTopic',
            );
          }
        } catch (e) {
          VendorAuthErrors.logDebug('[VendorFCM] unsubscribe skipped: $e');
        }
      }
      if (previousTopic != topic) {
        await messaging.subscribeToTopic(topic);
        await prefs.setString(_subscribedTopicKey, topic);
        if (kDebugMode) {
          debugPrint('[VendorNotify] FCM topic subscribed topic=$topic');
        }
      } else if (kDebugMode) {
        debugPrint('[VendorNotify] FCM topic already subscribed topic=$topic');
      }

      await _saveToken(vendorId, token, topic);

      if (kDebugMode) {
        debugPrint('[VendorNotify] FCM token registered vendor=$vendorId');
      }

      _tokenRefreshSub = messaging.onTokenRefresh.listen((t) async {
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

      final tokensCol = vendorRef.collection('deviceTokens');

      // One row per physical device; drop other rows that share this token.
      final dupes = await tokensCol.where('token', isEqualTo: token).get();
      for (final doc in dupes.docs) {
        if (doc.id != deviceId) {
          await doc.reference.delete();
        }
      }

      await tokensCol.doc(deviceId).set(
        {
          'token': token,
          'deviceId': deviceId,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        debugPrint('[VendorNotify] deviceTokens/$deviceId saved (unique)');
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
