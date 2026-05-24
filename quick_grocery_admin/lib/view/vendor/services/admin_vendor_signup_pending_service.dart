import 'package:cloud_firestore/cloud_firestore.dart';

/// Clears vendor signup pending flags (same keys as vendor app).
class AdminVendorSignupPendingService {
  AdminVendorSignupPendingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String emailKey(String email) {
    return email.trim().toLowerCase().replaceAll('@', '_at_').replaceAll('.', '_');
  }

  DocumentReference<Map<String, dynamic>> _doc(String email) {
    return _firestore
        .collection('vendor_signup_pending')
        .doc(emailKey(email));
  }

  Future<void> clearPending(String email) async {
    await _doc(email).delete();
  }
}
