import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'admin_vendor_auth_creator.dart';
import 'admin_vendor_signup_pending_service.dart';

/// Admin actions on vendor signup requests — Cloud Function primary, client fallback.
class AdminVendorRequestClient {
  AdminVendorRequestClient({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AdminVendorAuthCreator? authCreator,
    AdminVendorSignupPendingService? pendingService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1'),
        _authCreator = authCreator ?? AdminVendorAuthCreator(),
        _pending = pendingService ?? AdminVendorSignupPendingService();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _fn;
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

    try {
      final res = await _fn
          .httpsCallable('adminApproveVendorRequest')
          .call({'requestId': requestId});
      final data = res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final email = await _emailForRequest(requestId);
        if (email.isNotEmpty) await _pending.clearPending(email);
        return map;
      }
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AdminVendorRequest] CF approve failed code=${e.code} msg=${e.message}',
        );
      }
      if (e.code == 'not-found' || e.code == 'unavailable') {
        return _approveViaSecondaryApp(requestId);
      }
      throw Exception(_mapFunctionsError(e));
    }
  }

  Future<void> reject(String requestId, {String? reason}) async {
    await _ensureSignedIn();
    try {
      await _fn.httpsCallable('adminRejectVendorRequest').call({
        'requestId': requestId,
        'reason': reason ?? 'Rejected by admin',
      });
      final email = await _emailForRequest(requestId);
      if (email.isNotEmpty) await _pending.clearPending(email);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('[AdminVendorRequest] CF reject failed: ${e.code}');
      }
      if (e.code == 'not-found' || e.code == 'unavailable') {
        await _rejectLocal(requestId, reason: reason);
        return;
      }
      throw Exception(_mapFunctionsError(e));
    }
  }

  Future<void> deleteRequest(String requestId) async {
    await _ensureSignedIn();
    final snap = await _ref(requestId).get();
    final email = snap.data()?['email']?.toString() ?? '';
    await _ref(requestId).delete();
    await _pending.clearPending(email);
  }

  Future<String> _emailForRequest(String requestId) async {
    final snap = await _ref(requestId).get();
    return snap.data()?['email']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> _approveViaSecondaryApp(String requestId) async {
    final snap = await _ref(requestId).get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Vendor request not found.');
    }

    final data = snap.data()!;
    final status = data['status']?.toString() ?? 'pending';
    if (status == 'approved') {
      throw Exception('Vendor request is already approved.');
    }
    if (status == 'rejected') {
      throw Exception('Vendor request was rejected.');
    }

    final email = data['email']?.toString().trim().toLowerCase() ?? '';
    final password = data['password']?.toString() ?? '';
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Request email is invalid.');
    }
    if (password.length < 8) {
      throw Exception('Request password is missing or too short.');
    }

    final uid = await _authCreator.createVendorAuthAndFirestoreProfile(
      email: email,
      password: password,
      firstName: data['firstName']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? '',
      storeName: data['shopName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      shopAddress: data['shopAddress']?.toString() ?? '',
      vendorImage: data['vendorImage']?.toString() ?? '',
      shopImage: data['shopLogo']?.toString() ?? '',
    );

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

  Future<void> _rejectLocal(String requestId, {String? reason}) async {
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

  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'already-exists':
        return e.message ??
            'Email already exists in Firebase Authentication.';
      case 'invalid-argument':
        return e.message ?? 'Invalid vendor request data.';
      case 'failed-precondition':
        return e.message ?? 'Cannot approve this vendor request.';
      case 'permission-denied':
      case 'unauthenticated':
        return 'Admin permission required. Sign in with an admin account.';
      case 'not-found':
        return e.message ?? 'Vendor request not found.';
      default:
        return e.message ?? 'Vendor request action failed.';
    }
  }
}
