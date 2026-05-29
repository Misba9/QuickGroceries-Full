import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/core/firebase/callable_payload.dart';

import 'admin_delivery_auth_creator.dart';

String mapDeliveryFunctionsError(FirebaseFunctionsException e) {
  if (kDebugMode) {
    debugPrint('[DeliveryFunctions] code=${e.code} message=${e.message}');
  }
  switch (e.code) {
    case 'already-exists':
      return e.message ?? 'Email already exists for a delivery boy.';
    case 'invalid-argument':
      return e.message ?? 'Invalid delivery boy data.';
    case 'failed-precondition':
      return e.message ?? 'Could not complete delivery boy creation.';
    case 'not-found':
      return e.message ?? 'Delivery boy or Firebase Auth user not found.';
    case 'unauthenticated':
      return 'Sign in to the admin panel first.';
    case 'permission-denied':
      return 'Admin permission required for this action.';
    case 'unavailable':
      return 'Cloud Functions unavailable. Using offline auth creation.';
    case 'internal':
      return e.message?.isNotEmpty == true
          ? e.message!
          : 'Server error. Deploy Cloud Functions and check Firebase Console logs.';
    default:
      return e.message ?? 'Delivery boy operation failed (${e.code}).';
  }
}

/// Creates delivery Firebase Auth + Firestore `delivery_boys/{auth.uid}`.
class AdminDeliveryClient {
  AdminDeliveryClient({
    FirebaseFunctions? functions,
    AdminDeliveryAuthCreator? authCreator,
  }) : _fn = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _authCreator = authCreator ?? AdminDeliveryAuthCreator();

  final FirebaseFunctions _fn;
  final AdminDeliveryAuthCreator _authCreator;

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in to the admin panel first.');
    }
  }

  Future<Map<String, dynamic>> createDeliveryAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String image,
    required String licenceNumber,
  }) async {
    await _ensureSignedIn();
    final normalizedEmail = email.trim().toLowerCase();

    if (kDebugMode) {
      debugPrint(
        '[AdminDelivery] createDeliveryAccount email=$normalizedEmail',
      );
    }

    try {
      final payload = sanitizeCallableData({
        'email': normalizedEmail,
        'password': password,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'image': image,
        'licenceNumber': licenceNumber.trim(),
      });
      debugCallableData('adminCreateDeliveryAccount', payload);
      final res = await _fn
          .httpsCallable('adminCreateDeliveryAccount')
          .call(payload);
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        throw Exception('Sign in to the admin panel first.');
      }
      if (e.code == 'not-found' || e.code == 'unavailable') {
        if (kDebugMode) {
          debugPrint('[AdminDelivery] CF unavailable — secondary-app fallback');
        }
        final uid = await _authCreator.createDeliveryAuthAndFirestoreProfile(
          email: normalizedEmail,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          address: address,
          image: image,
          licenceNumber: licenceNumber,
        );
        return {
          'success': true,
          'authUid': uid,
          'deliveryBoyId': uid,
          'firestorePath': 'delivery_boys/$uid',
        };
      }
      throw Exception(mapDeliveryFunctionsError(e));
    }
  }
}
