import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/admin_firebase_options.dart';

/// Creates vendor Firebase Auth users via a secondary app so the admin session
/// stays signed in. Can write `vendors/{uid}` while signed in as the new vendor.
class AdminVendorAuthCreator {
  static const _secondaryAppName = 'VendorAuthCreator';

  Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: AdminFirebaseOptions.current,
      );
    }
  }

  Future<FirebaseAuth> _secondaryAuth() async {
    final app = await _secondaryApp();
    return FirebaseAuth.instanceFor(app: app);
  }

  Future<FirebaseFirestore> _secondaryFirestore() async {
    final app = await _secondaryApp();
    return FirebaseFirestore.instanceFor(app: app);
  }

  /// Returns Auth UID. Password is passed through unchanged (no trim).
  Future<String> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final auth = await _secondaryAuth();

    if (kDebugMode) {
      print('email: $normalizedEmail');
      print('password: $password');
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user?.uid;
      if (kDebugMode) {
        print('auth.uid: $uid');
      }
      if (uid == null || uid.isEmpty) {
        throw Exception('Firebase Auth user was created but UID is missing.');
      }
      return uid;
    } on FirebaseAuthException catch (e) {
      await auth.signOut();
      throw _mapAuthError(e);
    }
  }

  /// Creates Auth on secondary app + Firestore `vendors/{uid}` (no admin logout).
  /// Use when Cloud Functions are not deployed.
  Future<String> createVendorAuthAndFirestoreProfile({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String storeName,
    required String phone,
    required String shopAddress,
    required String vendorImage,
    required String shopImage,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final auth = await _secondaryAuth();
    final firestore = await _secondaryFirestore();

    if (kDebugMode) {
      print('email: $normalizedEmail');
      print('password: $password');
    }

    UserCredential credential;
    try {
      credential = await auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      await auth.signOut();
      throw _mapAuthError(e);
    }

    final uid = credential.user?.uid;
    if (kDebugMode) {
      print('auth.uid: $uid');
    }
    if (uid == null || uid.isEmpty) {
      await auth.signOut();
      throw Exception('Firebase Auth user was created but UID is missing.');
    }

    final ownerName = '$firstName $lastName'.trim();
    try {
      final ref = firestore.collection('vendors').doc(uid);
      await ref.set({
        'uid': uid,
        'id': uid,
        'auth_uid': uid,
        'email': normalizedEmail,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'ownerName': ownerName.isEmpty ? storeName : ownerName,
        'phone': phone.trim(),
        'shopName': storeName.trim(),
        'shop_name': storeName.trim(),
        'storeName': storeName.trim(),
        'shopAddress': shopAddress.trim(),
        'shop_address': shopAddress.trim(),
        'vendorImage': vendorImage,
        'vendor_image': vendorImage,
        'shopLogo': shopImage,
        'shop_image': shopImage,
        'status': 'active',
        'isApproved': true,
        'isBlocked': false,
        'is_active': true,
        'authSynced': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final saved = await ref.get();
      if (kDebugMode) {
        print('doc.exists: ${saved.exists}');
      }
      if (!saved.exists) {
        await credential.user?.delete();
        throw Exception('Vendor Firestore profile could not be saved.');
      }
    } catch (e) {
      try {
        await credential.user?.delete();
      } catch (_) {}
      rethrow;
    } finally {
      await auth.signOut();
    }

    return uid;
  }

  Exception _mapAuthError(FirebaseAuthException e) {
    if (kDebugMode) {
      debugPrint('[AdminVendorAuth] code=${e.code} message=${e.message}');
    }
    switch (e.code) {
      case 'email-already-in-use':
        return Exception(
          'Email already exists in Firebase Authentication. '
          'Use "Sync Firebase Auth" on Vendor List for existing vendors.',
        );
      case 'weak-password':
        return Exception('Password is too weak. Use at least 8 characters.');
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'operation-not-allowed':
        return Exception(
          'Email/password sign-in is disabled in Firebase Console.',
        );
      default:
        return Exception(
          e.message ?? 'Firebase Authentication creation failed.',
        );
    }
  }
}
