import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/core/firebase/callable_payload.dart';

import 'admin_vendor_auth_creator.dart';
import 'admin_vendor_http_client.dart';
import 'admin_vendor_signup_pending_service.dart';

/// Admin actions on vendor signup requests — callable primary, CORS HTTP fallback.
class AdminVendorRequestClient {
  AdminVendorRequestClient({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AdminVendorAuthCreator? authCreator,
    AdminVendorSignupPendingService? pendingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _fn = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
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

  bool _isCallableTransportError(FirebaseFunctionsException e) {
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') return true;
    if (kIsWeb && (e.code == 'internal' || e.code == 'unknown')) return true;
    final msg = (e.message ?? '').toLowerCase();
    return msg.contains('cors') ||
        msg.contains('failed to fetch') ||
        msg.contains('network');
  }

  Future<Map<String, dynamic>> approve(String requestId) async {
    await _ensureSignedIn();

    try {
      final payload = sanitizeCallableData({'requestId': requestId});
      debugCallableData('adminApproveVendorRequest', payload);
      final res = await _fn
          .httpsCallable('adminApproveVendorRequest')
          .call(payload);
      final data = res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        await _clearPendingForRequest(requestId);
        return map;
      }
      await _clearPendingForRequest(requestId);
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AdminVendorRequest] CF approve failed code=${e.code} msg=${e.message}',
        );
      }
      if (e.code == 'not-found' && e.message?.contains('function') == true) {
        return _approveViaHttp(requestId);
      }
      if (_isCallableTransportError(e)) {
        try {
          return await _approveViaHttp(requestId);
        } catch (httpErr) {
          if (kDebugMode) {
            debugPrint('[AdminVendorRequest] HTTP approve fallback: $httpErr');
          }
          return _approveViaSecondaryApp(requestId);
        }
      }
      throw Exception(_mapFunctionsError(e));
    }
  }

  Future<void> reject(String requestId, {String? reason}) async {
    await _ensureSignedIn();
    try {
      final payload = sanitizeCallableData({
        'requestId': requestId,
        'reason': reason ?? 'Rejected by admin',
      });
      debugCallableData('adminRejectVendorRequest', payload);
      await _fn.httpsCallable('adminRejectVendorRequest').call(payload);
      await _clearPendingForRequest(requestId);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('[AdminVendorRequest] CF reject failed: ${e.code}');
      }
      if (e.code == 'not-found' && e.message?.contains('function') == true) {
        await _rejectViaHttp(requestId, reason: reason);
        return;
      }
      if (_isCallableTransportError(e)) {
        try {
          await _rejectViaHttp(requestId, reason: reason);
          return;
        } catch (httpErr) {
          if (kDebugMode) {
            debugPrint('[AdminVendorRequest] HTTP reject fallback: $httpErr');
          }
          await _rejectLocal(requestId, reason: reason);
          return;
        }
      }
      throw Exception(_mapFunctionsError(e));
    }
  }

  Future<Map<String, dynamic>> _approveViaHttp(String requestId) async {
    if (kDebugMode) {
      debugPrint('[AdminVendorRequest] approve via CORS HTTP endpoint');
    }
    final map = await AdminVendorHttpClient.approveVendorRequest(requestId);
    await _clearPendingForRequest(requestId);
    return map;
  }

  Future<void> _rejectViaHttp(String requestId, {String? reason}) async {
    if (kDebugMode) {
      debugPrint('[AdminVendorRequest] reject via CORS HTTP endpoint');
    }
    await AdminVendorHttpClient.rejectVendorRequest(
      requestId: requestId,
      reason: reason,
    );
    await _clearPendingForRequest(requestId);
  }

  Future<void> deleteRequest(String requestId) async {
    await _ensureSignedIn();
    final snap = await _ref(requestId).get();
    final email = snap.data()?['email']?.toString() ?? '';
    await _ref(requestId).delete();
    await _pending.clearPending(email);
  }

  Future<void> _clearPendingForRequest(String requestId) async {
    final email = await _emailForRequest(requestId);
    if (email.isNotEmpty) await _pending.clearPending(email);
  }

  Future<String> _emailForRequest(String requestId) async {
    final snap = await _ref(requestId).get();
    return snap.data()?['email']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> _approveViaSecondaryApp(String requestId) async {
    if (kDebugMode) {
      debugPrint('[AdminVendorRequest] approve via secondary Firebase app');
    }
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

    return {'success': true, 'authUid': uid, 'firestorePath': 'vendors/$uid'};
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
        return e.message ?? 'Email already exists in Firebase Authentication.';
      case 'invalid-argument':
        return e.message ?? 'Invalid vendor request data.';
      case 'failed-precondition':
        return e.message ?? 'Cannot approve this vendor request.';
      case 'permission-denied':
      case 'unauthenticated':
        return 'Admin permission required. Sign in with an admin account.';
      case 'not-found':
        return e.message ?? 'Vendor request not found.';
      case 'internal':
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Server error during vendor approval. Deploy Cloud Functions and retry.';
      default:
        return e.message ?? 'Vendor request action failed.';
    }
  }
}
