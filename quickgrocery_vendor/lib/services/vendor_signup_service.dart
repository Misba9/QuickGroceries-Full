import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/auth/vendor_signup_result.dart';
import 'vendor_signup_pending_service.dart';

/// Submits vendor signup directly to Firestore `vendor_requests/` (no Cloud Functions).
class VendorSignupService {
  VendorSignupService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    VendorSignupPendingService? pendingService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _pending = pendingService ?? VendorSignupPendingService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final VendorSignupPendingService _pending;

  Future<String> _uploadImage(File file, String folder) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path =
        'vendor_signup/$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<bool> _hasPendingRequest(String email) async {
    if (await _pending.isPending(email)) return true;
    try {
      final snap = await _firestore
          .collection('vendor_requests')
          .where('email', isEqualTo: email)
          .limit(5)
          .get();
      return snap.docs.any(
        (d) => (d.data()['status']?.toString() ?? 'pending') == 'pending',
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[VendorSignup] pending check skipped: ${e.code}');
      }
      return false;
    }
  }

  Future<bool> _vendorEmailExists(String email) async {
    final snap = await _firestore
        .collection('vendors')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<VendorSignupResult> submitRequest({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String shopName,
    required String shopAddress,
    required File vendorImageFile,
    required File shopLogoFile,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      if (kDebugMode) {
        print('email: $normalizedEmail');
      }

      if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
        return const VendorSignupResult.failure('First and last name are required.');
      }
      if (shopName.trim().isEmpty || shopAddress.trim().isEmpty) {
        return const VendorSignupResult.failure('Shop name and address are required.');
      }
      if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
        return const VendorSignupResult.failure('Enter a valid email address.');
      }
      if (password.length < 8) {
        return const VendorSignupResult.failure(
          'Password must be at least 8 characters.',
        );
      }
      if (phone.trim().length < 10) {
        return const VendorSignupResult.failure('Enter a valid phone number.');
      }

      if (await _hasPendingRequest(normalizedEmail)) {
        return const VendorSignupResult.failure(
          'A signup request for this email is already pending approval.',
        );
      }
      if (await _vendorEmailExists(normalizedEmail)) {
        return const VendorSignupResult.failure(
          'A vendor with this email already exists. Try logging in.',
        );
      }

      final vendorImageUrl = await _uploadImage(vendorImageFile, 'vendor');
      final shopLogoUrl = await _uploadImage(shopLogoFile, 'shop');

      await _firestore.collection('vendor_requests').add({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'email': normalizedEmail,
        'password': password,
        'shopName': shopName.trim(),
        'shopAddress': shopAddress.trim(),
        'vendorImage': vendorImageUrl,
        'shopLogo': shopLogoUrl,
        'status': 'pending',
        'isApproved': false,
        'isBlocked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _pending.markPending(normalizedEmail);

      if (kDebugMode) {
        print('vendor_requests: saved');
      }

      return const VendorSignupResult.success(
        message: 'Request submitted successfully. Wait for admin approval.',
        needsApproval: true,
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('[VendorSignup] Firebase ${e.code}: ${e.message}');
      }
      return VendorSignupResult.failure(_firestoreMessage(e));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VendorSignup] error: $e');
      }
      return VendorSignupResult.failure(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Could not submit request. Deploy updated Firestore and Storage rules.';
      case 'unavailable':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Signup failed. Please try again.';
    }
  }
}
