import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'admin_vendor_auth_creator.dart';
import 'admin_vendor_signup_pending_service.dart';

/// Admin actions on vendor signup requests — Firestore + secondary-app Auth (no Cloud Functions).
class AdminVendorRequestClient {
  AdminVendorRequestClient({
    FirebaseFirestore? firestore,
    AdminVendorAuthCreator? authCreator,
    AdminVendorSignupPendingService? pendingService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authCreator = authCreator ?? AdminVendorAuthCreator(),
        _pending = pendingService ?? AdminVendorSignupPendingService();

  final FirebaseFirestore _firestore;
  final AdminVendorAuthCreator _authCreator;
  final AdminVendorSignupPendingService _pending;

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in to the admin panel first.');
    }
  }

  DocumentReference<Map<String, dynamic>> _ref(String requestId) {
    return _firestore.collection('vendor_requests').doc(requestId);
  }

  Future<Map<String, dynamic>> approve(String requestId) async {
    await _ensureSignedIn();

    final snap = await _ref(requestId).get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Vendor request not found.');
    }

    final data = snap.data()!;
    final status = data['status']?.toString() ?? 'pending';
    if (status == 'approved') {
      throw Exception('Request is already approved.');
    }
    if (status == 'rejected') {
      throw Exception('Request was rejected.');
    }

    final email = data['email']?.toString().trim().toLowerCase() ?? '';
    final password = data['password']?.toString() ?? '';
    final firstName = data['firstName']?.toString() ?? '';
    final lastName = data['lastName']?.toString() ?? '';
    final shopName = data['shopName']?.toString() ?? '';
    final shopAddress = data['shopAddress']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final vendorImage = data['vendorImage']?.toString() ?? '';
    final shopLogo = data['shopLogo']?.toString() ?? '';

    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Request email is invalid.');
    }
    if (password.length < 8) {
      throw Exception('Request password is missing or too short.');
    }

    if (kDebugMode) {
      print('email: $email');
    }

    final uid = await _authCreator.createVendorAuthAndFirestoreProfile(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      storeName: shopName,
      phone: phone,
      shopAddress: shopAddress,
      vendorImage: vendorImage,
      shopImage: shopLogo,
    );

    if (kDebugMode) {
      print('auth.uid: $uid');
      print('doc.exists: true');
    }

    await _ref(requestId).update({
      'status': 'approved',
      'isApproved': true,
      'authUid': uid,
      'approvedAt': FieldValue.serverTimestamp(),
      'password': FieldValue.delete(),
    });

    await _pending.clearPending(email);

    return {
      'success': true,
      'authUid': uid,
      'firestorePath': 'vendors/$uid',
    };
  }

  Future<void> reject(String requestId, {String? reason}) async {
    await _ensureSignedIn();
    final snap = await _ref(requestId).get();
    if (!snap.exists) {
      throw Exception('Vendor request not found.');
    }

    final email = snap.data()?['email']?.toString() ?? '';

    await _ref(requestId).update({
      'status': 'rejected',
      'isApproved': false,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason?.trim().isNotEmpty == true
          ? reason!.trim()
          : 'Rejected by admin',
      'password': FieldValue.delete(),
    });

    await _pending.clearPending(email);
  }

  Future<void> deleteRequest(String requestId) async {
    await _ensureSignedIn();
    final snap = await _ref(requestId).get();
    final email = snap.data()?['email']?.toString() ?? '';
    await _ref(requestId).delete();
    await _pending.clearPending(email);
  }
}
