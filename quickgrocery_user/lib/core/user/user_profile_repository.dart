import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firestore/firestore_retry.dart';
import 'user_profile_cache.dart';

/// Persists user profile to Firestore (`customers` + `users`) and local cache.
class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const customers = 'customers';
  static const users = 'users';

  DocumentReference<Map<String, dynamic>> _customerRef(String uid) =>
      _firestore.collection(customers).doc(uid);

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(users).doc(uid);

  /// True when name + gender exist (minimum onboarding complete).
  Future<bool> isProfileComplete(String uid) async {
    if (await UserProfileCache.isProfileCompleteCached()) return true;

    final snap = await withFirestoreRetry(
      () => _customerRef(uid).get().timeout(const Duration(seconds: 10)),
    );
    if (!snap.exists) return false;

    final data = snap.data() ?? {};
    if (data['profile_complete'] == true) return true;

    final name = (data['name'] ?? '').toString().trim();
    final gender = (data['gender'] ?? '').toString().trim();
    final complete = name.isNotEmpty && gender.isNotEmpty;

    if (complete) {
      await UserProfileCache.setProfileComplete(true);
    }
    return complete;
  }

  /// Pull Firestore profile into memory + SharedPreferences.
  Future<void> hydrateLocal(String uid) async {
    try {
      final snap = await withFirestoreRetry(
        () => _customerRef(uid).get().timeout(const Duration(seconds: 10)),
      );
      if (!snap.exists) return;
      final data = snap.data() ?? {};

      final name = (data['name'] ?? '').toString();
      final email = (data['email'] ?? '').toString();
      final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
      final gender = (data['gender'] ?? '').toString();
      final image = (data['profile_image'] ?? data['image'] ?? '').toString();
      final defaultAddr =
          (data['default_address_id'] ?? data['defaultAddressId'] ?? '')
              .toString();

      final complete = name.trim().isNotEmpty && gender.trim().isNotEmpty;

      await UserProfileCache.saveProfile(
        uid: uid,
        nameValue: name,
        emailValue: email,
        phoneValue: phone,
        genderValue: gender,
        imageUrl: image,
        profileCompleteFlag: data['profile_complete'] == true || complete,
        defaultAddressIdValue: defaultAddr.isEmpty ? null : defaultAddr,
      );

      // Ensure callers always see device fields (empty string when absent).
      // Values are never wiped here — hydrate is read-only.

      final checkout = data['checkout_preferences'];
      if (checkout is Map<String, dynamic>) {
        final pm = checkout['payment_method']?.toString();
        final idx = checkout['address_index'];
        if (pm != null && pm.isNotEmpty) {
          await UserProfileCache.saveCheckoutPrefs(paymentMethodId: pm);
        }
        if (idx is int) {
          await UserProfileCache.saveCheckoutPrefs(addressIndex: idx);
        }
        final instr = checkout['delivery_instructions'];
        if (instr is Map<String, dynamic>) {
          await UserProfileCache.saveCheckoutPrefs(
            instructionsJson: jsonEncode(instr),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[UserProfileRepository] hydrate failed: $e');
    }
  }

  /// Normalized profile map for APIs / UI — always includes device fields.
  static Map<String, dynamic> deviceFieldsFromData(Map<String, dynamic> data) {
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = (data[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final appVersion = pick(['appVersion', 'app_version', 'version']);
    final buildNumber = pick(['buildNumber', 'build_number']);
    return {
      'platform': pick(['platform', 'fcmPlatform', 'device_type']),
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'deviceModel': pick(['deviceModel', 'device_model']),
      'osVersion': pick(['osVersion', 'os_version']),
      'lastSeen': data['lastSeen'] ?? data['last_seen'] ?? data['last_active_at'],
      'lastLogin': data['lastLogin'] ?? data['last_login'],
    };
  }

  /// Fetch customer profile with device fields always present (merge-safe read).
  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final snap = await withFirestoreRetry(
      () => _customerRef(uid).get().timeout(const Duration(seconds: 10)),
    );
    if (!snap.exists) return null;
    final data = Map<String, dynamic>.from(snap.data() ?? {});
    data.addAll(deviceFieldsFromData(data));
    return data;
  }

  /// Merge-write profile fields to both collections.
  /// Empty / null string values are stripped so existing fields are preserved.
  Future<void> saveProfile({
    required String uid,
    required Map<String, dynamic> fields,
    bool markComplete = false,
  }) async {
    final payload = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      payload[key] = value;
    });
    payload['uid'] = uid;
    payload['updated_at'] = FieldValue.serverTimestamp();
    if (markComplete) payload['profile_complete'] = true;

    await Future.wait([
      _customerRef(uid).set(payload, SetOptions(merge: true)),
      _userRef(uid).set(payload, SetOptions(merge: true)),
    ]);

    await UserProfileCache.saveProfile(
      uid: uid,
      nameValue: payload['name']?.toString(),
      emailValue: payload['email']?.toString(),
      phoneValue: payload['phone']?.toString(),
      genderValue: payload['gender']?.toString(),
      imageUrl: payload['profile_image']?.toString(),
      profileCompleteFlag: markComplete ? true : null,
      defaultAddressIdValue: payload['default_address_id']?.toString(),
    );
  }

  Future<void> saveCheckoutPreferences({
    required String uid,
    String? paymentMethodId,
    int? addressIndex,
    Map<String, dynamic>? deliveryInstructions,
    String? lastOrderId,
  }) async {
    final checkout = <String, dynamic>{
      if (paymentMethodId != null) 'payment_method': paymentMethodId,
      if (addressIndex != null) 'address_index': addressIndex,
      if (deliveryInstructions != null)
        'delivery_instructions': deliveryInstructions,
      if (lastOrderId != null) 'last_order_id': lastOrderId,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (checkout.isEmpty) return;

    final patch = {'checkout_preferences': checkout};
    await Future.wait([
      _customerRef(uid).set(patch, SetOptions(merge: true)),
      _userRef(uid).set(patch, SetOptions(merge: true)),
    ]);

    await UserProfileCache.saveCheckoutPrefs(
      paymentMethodId: paymentMethodId,
      addressIndex: addressIndex,
      orderId: lastOrderId,
    );
  }

  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Mirror default delivery address snapshot to `customers` + `users`.
  Future<void> syncDefaultAddress({
    required String uid,
    required String addressId,
    required String fullAddress,
    String? area,
    String? addressType,
    String? pincode,
    String? city,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>>? savedAddresses,
  }) async {
    final payload = <String, dynamic>{
      'default_address_id': addressId,
      'default_address': fullAddress,
      if (area != null && area.isNotEmpty) 'apartment_flat': area,
      if (area != null && area.isNotEmpty) 'landmark': area,
      if (city != null && city.isNotEmpty) 'city': city,
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
      if (latitude != null && longitude != null)
        'location': GeoPoint(latitude, longitude),
      if (savedAddresses != null) 'saved_addresses': savedAddresses,
      'updated_at': FieldValue.serverTimestamp(),
    };

    await Future.wait([
      _customerRef(uid).set(payload, SetOptions(merge: true)),
      _userRef(uid).set(payload, SetOptions(merge: true)),
    ]);

    await UserProfileCache.saveProfile(
      uid: uid,
      defaultAddressIdValue: addressId,
    );
  }
}
