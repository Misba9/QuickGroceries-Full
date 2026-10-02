import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Public Razorpay Key Id for Standard Checkout.
///
/// Prefer Firestore `app_config/payments.razorpayKeyId` so the key can be
/// rotated without an app release. The Key **Secret** must never live here.
const String kRazorpayPublicKeyIdFallback = 'rzp_live_SLDUzSlRIhWOXG';

Future<String> resolveRazorpayPublicKeyId() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('payments')
        .get();
    final fromDoc = (snap.data()?['razorpayKeyId'] ??
            snap.data()?['razorpay_key_id'] ??
            '')
        .toString()
        .trim();
    if (fromDoc.startsWith('rzp_')) return fromDoc;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Razorpay public key lookup failed: $e');
    }
  }
  return kRazorpayPublicKeyIdFallback;
}
