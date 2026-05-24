import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/auth/vendor_auth_errors.dart';
import 'firebase_service.dart';

/// Creates and reads vendor profiles at `vendors/{uid}`.
class VendorDocumentService {
  VendorDocumentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> docRef(String uid) {
    return _firestore.doc(FirebaseService.vendorDocPath(uid));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchByUid(String uid) async {
    final path = FirebaseService.vendorDocPath(uid);
    VendorAuthErrors.logDebug('fetch vendor path=$path');
    if (kDebugMode) {
      print('Vendor UID: $uid');
    }
    final doc = await docRef(uid).get();
    if (kDebugMode) {
      print('Vendor doc id: ${doc.id}');
      print('doc.exists: ${doc.exists}');
    }
    VendorAuthErrors.logDebug(
      'vendor doc id=${doc.id} exists=${doc.exists} path=$path',
    );
    return doc;
  }

  /// Creates `vendors/{uid}` immediately after Firebase Auth signup.
  Future<void> createOnSignup({
    required String uid,
    required String email,
    required String ownerName,
    required String storeName,
  }) async {
    final data = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'ownerName': ownerName.trim(),
      'storeName': storeName.trim(),
      'isApproved': false,
      'isBlocked': false,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      // Legacy fields used across the vendor app UI.
      'id': uid,
      'auth_uid': uid,
      'first_name': ownerName.trim(),
      'shop_name': storeName.trim(),
      'is_active': true,
    };

    VendorAuthErrors.logDebug('creating vendor doc uid=$uid');
    await docRef(uid).set(data);
    VendorAuthErrors.logDebug('vendor doc created at ${FirebaseService.vendorDocPath(uid)}');
  }

  Future<bool> existsAtUid(String uid) async {
    final doc = await fetchByUid(uid);
    return doc.exists;
  }
}
