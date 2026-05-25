import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'admin_vendor_auth_creator.dart';
import 'admin_vendor_http_client.dart';

/// Maps Cloud Functions errors to readable admin messages.
String mapVendorFunctionsError(FirebaseFunctionsException e) {
  if (kDebugMode) {
    debugPrint('[VendorFunctions] code=${e.code} message=${e.message}');
  }
  switch (e.code) {
    case 'already-exists':
      return e.message ??
          'Email already exists. Use Sync Firebase Auth on Vendor List.';
    case 'invalid-argument':
      return e.message ?? 'Invalid vendor data. Check all required fields.';
    case 'failed-precondition':
      return e.message ?? 'Could not complete vendor operation.';
    case 'not-found':
      return e.message ?? 'Vendor or Firebase Auth user not found.';
    case 'unauthenticated':
      return 'Sign in to the admin panel first.';
    case 'permission-denied':
      return 'Admin permission required for this action.';
    case 'unavailable':
      return 'Cloud Functions unavailable. Deploy functions or use offline sync.';
    case 'internal':
      return e.message?.isNotEmpty == true
          ? e.message!
          : 'Server error. Deploy Cloud Functions and check Firebase Console logs.';
    default:
      return e.message ?? 'Vendor operation failed (${e.code}).';
  }
}

/// Creates vendor Firebase Auth + Firestore `vendors/{auth.uid}`.
class AdminVendorClient {
  AdminVendorClient({
    FirebaseFunctions? functions,
    AdminVendorAuthCreator? authCreator,
  })  : _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1'),
        _authCreator = authCreator ?? AdminVendorAuthCreator();

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
    }

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
      if (e.code == 'unauthenticated') {
        throw Exception('Sign in to the admin panel first.');
      }
      if (e.code == 'not-found' || e.code == 'unavailable') {
        if (kDebugMode) {
          debugPrint('[AdminVendor] CF unavailable — secondary-app fallback');
        }
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
      throw Exception(mapVendorFunctionsError(e));
    }
  }

  Future<Map<String, dynamic>> migrateVendorAuth({
    required String vendorDocId,
    required String password,
  }) async {
    await _ensureSignedIn();
    if (kDebugMode) {
      debugPrint('[AdminVendor] migrate start vendorDocId=$vendorDocId');
    }
    try {
      final res = await _fn.httpsCallable('adminMigrateVendorAuth').call({
        'vendorDocId': vendorDocId,
        'password': password,
      });
      final data = res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (kDebugMode) {
          debugPrint('[AdminVendor] migrate success uid=${map['authUid']}');
        }
        return map;
      }
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('[AdminVendor] migrate CF failed code=${e.code}');
      }
      if (_shouldTryHttp(e)) {
        if (kDebugMode) {
          debugPrint('[AdminVendor] migrate trying HTTP fallback');
        }
        return AdminVendorHttpClient.migrateVendorAuth(
          vendorDocId: vendorDocId,
          password: password,
        );
      }
      if (e.code == 'not-found' || e.code == 'unavailable') {
        return _migrateViaSecondaryApp(vendorDocId: vendorDocId, password: password);
      }
      throw Exception(mapVendorFunctionsError(e));
    }
  }

  /// Restore by Firestore doc id or shop name (e.g. Honey Traders).
  Future<Map<String, dynamic>> restoreVendorAuth({
    String? vendorDocId,
    String? shopName,
    required String password,
  }) async {
    await _ensureSignedIn();
    if (kDebugMode) {
      debugPrint(
        '[AdminVendor] restore shopName=$shopName vendorDocId=$vendorDocId',
      );
    }
    try {
      final res = await _fn.httpsCallable('adminRestoreVendorAuth').call({
        if (vendorDocId != null && vendorDocId.isNotEmpty)
          'vendorDocId': vendorDocId,
        if (shopName != null && shopName.isNotEmpty) 'shopName': shopName,
        'password': password,
      });
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      if (_shouldTryHttp(e)) {
        return AdminVendorHttpClient.restoreVendorAuth(
          vendorDocId: vendorDocId,
          shopName: shopName,
          password: password,
        );
      }
      if (e.code == 'not-found' || e.code == 'unavailable') {
        final id = vendorDocId;
        if (id == null || id.isEmpty) {
          throw Exception(
            'Deploy adminRestoreVendorAuth or pass vendorDocId from Vendor List.',
          );
        }
        return _migrateViaSecondaryApp(vendorDocId: id, password: password);
      }
      throw Exception(mapVendorFunctionsError(e));
    }
  }

  bool _shouldTryHttp(FirebaseFunctionsException e) {
    if (kIsWeb &&
        (e.code == 'internal' ||
            e.code == 'unavailable' ||
            e.code == 'unknown')) {
      return true;
    }
    final msg = (e.message ?? '').toLowerCase();
    return msg.contains('cors') || msg.contains('blocked');
  }

  Future<Map<String, dynamic>> _migrateViaSecondaryApp({
    required String vendorDocId,
    required String password,
  }) async {
    if (kDebugMode) {
      debugPrint('[AdminVendor] secondary-app migrate vendorDocId=$vendorDocId');
    }
    final uid = await _authCreator.migrateLegacyVendorDocument(
      legacyDocId: vendorDocId,
      password: password,
    );
    return {
      'success': true,
      'authUid': uid,
      'previousDocId': vendorDocId,
      'firestorePath': 'vendors/$uid',
    };
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
      return Map<String, dynamic>.from(data);
    }
    return {'success': true};
  }

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
    try {
      await _fn.httpsCallable('adminSyncVendorAuthPassword').call({
        'email': email.trim().toLowerCase(),
        'password': password,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(mapVendorFunctionsError(e));
    }
  }

  Future<void> rollbackVendorAuth(String authUid) async {
    await _ensureSignedIn();
    try {
      await _fn.httpsCallable('adminRollbackVendorAuth').call({
        'authUid': authUid,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(mapVendorFunctionsError(e));
    }
  }
}
