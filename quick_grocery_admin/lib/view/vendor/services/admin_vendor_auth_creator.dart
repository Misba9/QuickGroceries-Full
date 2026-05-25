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
      debugPrint('[AdminVendorAuth] email: $normalizedEmail');
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
      debugPrint('[AdminVendorAuth] email: $normalizedEmail');
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
        'firebaseAuth': true,
        'syncStatus': 'synced',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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

  /// Migrates legacy `vendors/{legacyDocId}` → `vendors/{authUid}` when Cloud Functions unavailable.
  /// Cannot link existing Auth email without Admin SDK — deploy functions for that case.
  Future<String> migrateLegacyVendorDocument({
    required String legacyDocId,
    required String password,
  }) async {
    final primaryFs = FirebaseFirestore.instance;
    final legacySnap = await primaryFs.collection('vendors').doc(legacyDocId).get();
    if (!legacySnap.exists || legacySnap.data() == null) {
      throw Exception('Vendor document not found.');
    }

    final data = legacySnap.data()!;
    final email = (data['email']?.toString() ?? '').trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Vendor email is invalid.');
    }

    final firstName = data['firstName']?.toString() ?? data['first_name']?.toString() ?? '';
    final lastName = data['lastName']?.toString() ?? data['last_name']?.toString() ?? '';
    final shopName = data['shopName']?.toString() ??
        data['shop_name']?.toString() ??
        data['storeName']?.toString() ??
        '';
    final phone = data['phone']?.toString() ?? '';
    final shopAddress = data['shopAddress']?.toString() ?? data['shop_address']?.toString() ?? '';
    final vendorImage = data['vendorImage']?.toString() ?? data['vendor_image']?.toString() ?? '';
    final shopImage = data['shopImage']?.toString() ?? data['shop_image']?.toString() ?? '';

    if (kDebugMode) {
      debugPrint('[AdminVendorAuth] migrateLegacy doc=$legacyDocId email=$email');
    }

    final uid = await createUserWithEmailAndPassword(email: email, password: password);

    final ownerName = '$firstName $lastName'.trim();
    final payload = {
      ...data,
      'uid': uid,
      'id': uid,
      'auth_uid': uid,
      'authUid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'first_name': firstName,
      'last_name': lastName,
      'ownerName': ownerName.isEmpty ? shopName : ownerName,
      'shopName': shopName,
      'shop_name': shopName,
      'storeName': shopName,
      'phone': phone,
      'shopAddress': shopAddress,
      'shop_address': shopAddress,
      'vendorImage': vendorImage,
      'vendor_image': vendorImage,
      'shopImage': shopImage,
      'shop_image': shopImage,
      'status': 'approved',
      'isApproved': true,
      'isBlocked': false,
      'is_active': true,
      'isActive': true,
      'authSynced': true,
      'firebaseAuth': true,
      'syncStatus': 'synced',
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
      if (legacyDocId != uid) 'migratedFrom': legacyDocId,
    };

    final targetRef = primaryFs.collection('vendors').doc(uid);
    await targetRef.set(payload, SetOptions(merge: true));

    if (legacyDocId != uid) {
      await primaryFs.collection('vendors').doc(legacyDocId).delete();
      if (kDebugMode) {
        debugPrint('[AdminVendorAuth] deleted legacy vendors/$legacyDocId');
      }
    }

    if (kDebugMode) {
      debugPrint('[AdminVendorAuth] migrateLegacy success vendors/$uid');
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
