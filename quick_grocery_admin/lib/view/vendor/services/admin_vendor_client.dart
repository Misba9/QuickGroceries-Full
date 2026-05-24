import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'admin_vendor_auth_creator.dart';

/// Creates vendor Firebase Auth + Firestore `vendors/{auth.uid}`.
///
/// Primary: Cloud Function (Admin SDK) — atomic, safe on web admin.
/// Fallback: secondary Firebase app creates Auth + writes Firestore as vendor.
class AdminVendorClient {
  AdminVendorClient({
    FirebaseFunctions? functions,
    AdminVendorAuthCreator? authCreator,
  })  : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: _region,
            ),
        _authCreator = authCreator ?? AdminVendorAuthCreator();

  static const _region = 'us-central1';

  final FirebaseFunctions _fn;
  final AdminVendorAuthCreator _authCreator;

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in to the admin panel first.');
    }
  }

  Map<String, dynamic> _payload({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String storeName,
    required String phone,
    required String shopAddress,
    required String vendorImage,
    required String shopImage,
    String? authUid,
  }) {
    return {
      if (authUid != null && authUid.isNotEmpty) 'authUid': authUid,
      'email': email.trim().toLowerCase(),
      'password': password,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'storeName': storeName.trim(),
      'phone': phone.trim(),
      'shopAddress': shopAddress.trim(),
      'vendorImage': vendorImage,
      'shopImage': shopImage,
    };
  }

  Future<Map<String, dynamic>> createVendorAccount({
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
    await _ensureSignedIn();

    final normalizedEmail = email.trim().toLowerCase();

    if (kDebugMode) {
      debugPrint('[AdminVendor] createVendorAccount email=$normalizedEmail');
      print('email: $normalizedEmail');
    }

    // 1) Prefer Cloud Function (Admin SDK creates Auth + Firestore atomically).
    try {
      return await _createViaCloudFunction(
        email: normalizedEmail,
        password: password,
        firstName: firstName,
        lastName: lastName,
        storeName: storeName,
        phone: phone,
        shopAddress: shopAddress,
        vendorImage: vendorImage,
        shopImage: shopImage,
      );
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AdminVendor] CF create failed code=${e.code} — trying secondary-app fallback',
        );
      }
      if (e.code == 'unauthenticated') {
        throw Exception('Sign in to the admin panel first.');
      }
      if (e.code == 'already-exists') {
        throw Exception(e.message ?? 'Vendor or email already exists.');
      }
      if (e.code == 'not-found' ||
          e.code == 'unavailable' ||
          e.code == 'internal') {
        return _createViaSecondaryApp(
          email: normalizedEmail,
          password: password,
          firstName: firstName,
          lastName: lastName,
          storeName: storeName,
          phone: phone,
          shopAddress: shopAddress,
          vendorImage: vendorImage,
          shopImage: shopImage,
        );
      }
      throw Exception(e.message ?? 'Failed to create vendor account.');
    }
  }

  /// Migrate legacy Firestore vendor → Firebase Auth + vendors/{auth.uid}.
  Future<Map<String, dynamic>> migrateVendorAuth({
    required String vendorDocId,
    required String password,
  }) async {
    await _ensureSignedIn();
    if (kDebugMode) {
      print('email: migrate vendorDocId=$vendorDocId');
    }
    try {
      final res = await _fn.httpsCallable('adminMigrateVendorAuth').call({
        'vendorDocId': vendorDocId,
        'password': password,
      });
      final data = res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final uid = map['authUid']?.toString() ?? '';
        if (kDebugMode) {
          print('auth.uid: $uid');
        }
        return map;
      }
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        e.message ??
            'Migration failed. Deploy adminMigrateVendorAuth Cloud Function.',
      );
    }
  }

  Future<Map<String, dynamic>> _createViaCloudFunction({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String storeName,
    required String phone,
    required String shopAddress,
    required String vendorImage,
    required String shopImage,
    String? authUid,
  }) async {
    final res = await _fn.httpsCallable('adminCreateVendorAccount').call(
      _payload(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        storeName: storeName,
        phone: phone,
        shopAddress: shopAddress,
        vendorImage: vendorImage,
        shopImage: shopImage,
        authUid: authUid,
      ),
    );

    final data = res.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final uid = map['authUid']?.toString() ?? '';
      if (kDebugMode) {
        print('auth.uid: $uid');
        debugPrint('[AdminVendor] CF created path=${map['firestorePath']}');
      }
      return map;
    }
    return {'success': true};
  }

  /// Secondary Firebase app: Auth + Firestore write without logging admin out.
  Future<Map<String, dynamic>> _createViaSecondaryApp({
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
    final uid = await _authCreator.createVendorAuthAndFirestoreProfile(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      storeName: storeName,
      phone: phone,
      shopAddress: shopAddress,
      vendorImage: vendorImage,
      shopImage: shopImage,
    );

    if (kDebugMode) {
      print('auth.uid: $uid');
      print('doc.exists: true');
    }

    return {
      'success': true,
      'authUid': uid,
      'vendorId': uid,
      'firestorePath': 'vendors/$uid',
    };
  }

  Future<void> syncAuthPassword({
    required String email,
    required String password,
  }) async {
    await _ensureSignedIn();
    await _fn.httpsCallable('adminSyncVendorAuthPassword').call({
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }
}
