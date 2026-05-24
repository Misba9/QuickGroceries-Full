import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight pending flag (no password) so login can detect unapproved signups without Cloud Functions.
class VendorSignupPendingService {
  VendorSignupPendingService({FirebaseFirestore? firestore})
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

  Future<void> markPending(String email) async {
    final normalized = email.trim().toLowerCase();
    await _doc(normalized).set({
      'email': normalized,
      'pending': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearPending(String email) async {
    await _doc(email).delete();
  }

  Future<bool> isPending(String email) async {
    final snap = await _doc(email).get();
    return snap.exists && snap.data()?['pending'] == true;
  }
}
