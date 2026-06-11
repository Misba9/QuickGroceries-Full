import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Resolves customer phone from order fields or `customers/{uid}` profile.
class CustomerPhoneResolver {
  CustomerPhoneResolver._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, String> _cache = {};

  static String fromOrderMap(Map<String, dynamic> data) {
    final addressSnapshot = data['address_snapshot'];
    final snapshot = addressSnapshot is Map
        ? Map<String, dynamic>.from(addressSnapshot)
        : null;

    return _firstNonEmpty([
      data['phone'],
      data['customerPhone'],
      data['customer_phone'],
      data['phoneNumber'],
      data['phone_number'],
      data['mobile'],
      data['customerMobile'],
      snapshot?['mobile'],
      snapshot?['phone'],
      snapshot?['phoneNumber'],
      snapshot?['phone_number'],
    ]);
  }

  static Future<String> resolve({
    required String orderPhone,
    required String customerUid,
  }) async {
    final direct = orderPhone.trim();
    if (direct.isNotEmpty) return direct;

    final uid = customerUid.trim();
    if (uid.isEmpty) return '';

    final cached = _cache[uid];
    if (cached != null) return cached;

    try {
      final customer = await _firestore.collection('customers').doc(uid).get();
      var phone = _extractPhone(customer.data());
      if (phone.isEmpty) {
        final user = await _firestore.collection('users').doc(uid).get();
        phone = _extractPhone(user.data());
      }
      _cache[uid] = phone;
      if (kDebugMode && phone.isNotEmpty) {
        debugPrint('[CustomerPhoneResolver] resolved uid=$uid phone=$phone');
      }
      return phone;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CustomerPhoneResolver] lookup failed uid=$uid: $e');
      }
      return '';
    }
  }

  static String _extractPhone(Map<String, dynamic>? data) {
    if (data == null) return '';
    return _firstNonEmpty([
      data['phone'],
      data['phoneNumber'],
      data['phone_number'],
      data['mobile'],
      data['contact'],
    ]);
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}
