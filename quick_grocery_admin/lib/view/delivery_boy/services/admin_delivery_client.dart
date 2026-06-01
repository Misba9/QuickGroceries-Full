import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/core/firebase/callable_payload.dart';

import 'admin_delivery_auth_creator.dart';
import 'admin_delivery_http_client.dart';

/// Maps Cloud Functions errors to readable admin messages.
String mapDeliveryFunctionsError(FirebaseFunctionsException e) {
  final details = e.details?.toString();
  if (kDebugMode) {
    debugPrint(
      '[DeliveryFunctions] code=${e.code} message=${e.message} details=$details',
    );
  }

  final msg = _resolveMessage(e);
  switch (e.code) {
    case 'already-exists':
      return msg ?? 'Email already exists for a delivery boy.';
    case 'invalid-argument':
      return msg ?? 'Invalid delivery boy data.';
    case 'failed-precondition':
      return msg ?? 'Could not complete delivery boy creation.';
    case 'not-found':
      return msg ?? 'Delivery boy or Firebase Auth user not found.';
    case 'unauthenticated':
      return 'Sign in to the admin panel first.';
    case 'permission-denied':
      return msg ?? 'Admin permission required for this action.';
    case 'unavailable':
      return msg ?? 'Cloud Functions unavailable. Using offline auth creation.';
    case 'internal':
      return msg ??
          'Server error while creating delivery boy. Check Firebase Console logs.';
    default:
      return msg ?? 'Delivery boy operation failed (${e.code}).';
  }
}

String? _resolveMessage(FirebaseFunctionsException e) {
  final message = e.message?.trim();
  if (message != null &&
      message.isNotEmpty &&
      message.toLowerCase() != 'internal') {
    return message;
  }
  final details = e.details;
  if (details is String && details.trim().isNotEmpty) return details.trim();
  if (details is Map && details['message'] != null) {
    return details['message'].toString();
  }
  return null;
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
      return await _createViaCloudFunction(
        email: normalizedEmail,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: address,
        image: image,
        licenceNumber: licenceNumber,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        throw Exception('Sign in to the admin panel first.');
      }
      if (_shouldTryHttp(e)) {
        if (kDebugMode) {
          debugPrint('[AdminDelivery] callable failed — trying HTTP fallback');
        }
        try {
          return await AdminDeliveryHttpClient.createDeliveryAccount(
            email: normalizedEmail,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            address: address,
            image: image,
            licenceNumber: licenceNumber,
          );
        } catch (httpErr) {
          throw Exception(httpErr.toString().replaceFirst('Exception: ', ''));
        }
      }
      if (e.code == 'not-found' || e.code == 'unavailable') {
        if (kDebugMode) {
          debugPrint('[AdminDelivery] CF unavailable — secondary-app fallback');
        }
        return _createViaSecondaryApp(
          email: normalizedEmail,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          address: address,
          image: image,
          licenceNumber: licenceNumber,
        );
      }
      throw Exception(mapDeliveryFunctionsError(e));
    }
  }

  bool _shouldTryHttp(FirebaseFunctionsException e) {
    if (!kIsWeb) return false;
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') return true;
    if (_isCallableTransportError(e)) return true;
    return false;
  }

  bool _isCallableTransportError(FirebaseFunctionsException e) {
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') return true;
    if (kIsWeb && (e.code == 'internal' || e.code == 'unknown')) return true;
    final msg = (e.message ?? '').toLowerCase();
    return msg.contains('cors') ||
        msg.contains('failed to fetch') ||
        msg.contains('network') ||
        msg == 'internal';
  }

  Future<Map<String, dynamic>> _createViaCloudFunction({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String image,
    required String licenceNumber,
  }) async {
    final payload = sanitizeCallableData({
      'email': email,
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
  }

  Future<Map<String, dynamic>> _createViaSecondaryApp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String image,
    required String licenceNumber,
  }) async {
    final uid = await _authCreator.createDeliveryAuthAndFirestoreProfile(
      email: email,
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
}
