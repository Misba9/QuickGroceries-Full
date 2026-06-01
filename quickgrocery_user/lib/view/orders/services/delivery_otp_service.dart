import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Server-issued delivery OTP stored on `customers/{uid}/delivery_otps/{orderId}`.
class DeliveryOtpService {
  static Stream<String?> watchOtp(String orderId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty || orderId.isEmpty) {
      return Stream.value(null);
    }
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(uid)
        .collection('delivery_otps')
        .doc(orderId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final otp = snap.data()?['otp']?.toString() ?? '';
      return otp.length == 4 ? otp : null;
    });
  }
}
