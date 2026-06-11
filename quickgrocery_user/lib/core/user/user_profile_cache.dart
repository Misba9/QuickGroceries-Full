import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for user profile + checkout preferences (offline / fast boot).
abstract final class UserProfileCache {
  static const _prefix = 'user_profile_';

  static const name = '${_prefix}name';
  static const email = '${_prefix}email';
  static const phone = '${_prefix}phone';
  static const gender = '${_prefix}gender';
  static const image = '${_prefix}image';
  static const profileComplete = '${_prefix}complete';
  static const languageCode = '${_prefix}language_code';
  static const countryCode = '${_prefix}country_code';
  static const defaultAddressId = '${_prefix}default_address_id';
  static const lastPaymentMethod = '${_prefix}last_payment_method';
  static const lastDeliveryInstructions = '${_prefix}last_delivery_instructions';
  static const lastAddressIndex = '${_prefix}last_address_index';
  static const lastOrderId = '${_prefix}last_order_id';

  static Future<void> saveProfile({
    required String uid,
    String? nameValue,
    String? emailValue,
    String? phoneValue,
    String? genderValue,
    String? imageUrl,
    bool? profileCompleteFlag,
    String? defaultAddressIdValue,
  }) async {
    final pref = await SharedPreferences.getInstance();
    if (nameValue != null) await pref.setString(name, nameValue);
    if (emailValue != null) await pref.setString(email, emailValue);
    if (phoneValue != null) await pref.setString(phone, phoneValue);
    if (genderValue != null) await pref.setString(gender, genderValue);
    if (imageUrl != null) await pref.setString(image, imageUrl);
    if (profileCompleteFlag != null) {
      await pref.setBool(profileComplete, profileCompleteFlag);
    }
    if (defaultAddressIdValue != null) {
      await pref.setString(defaultAddressId, defaultAddressIdValue);
    }
    await pref.setString('${_prefix}uid', uid);
  }

  static Future<Map<String, String>> readProfile() async {
    final pref = await SharedPreferences.getInstance();
    return {
      'name': pref.getString(name) ?? '',
      'email': pref.getString(email) ?? '',
      'phone': pref.getString(phone) ?? '',
      'gender': pref.getString(gender) ?? '',
      'image': pref.getString(image) ?? '',
      'defaultAddressId': pref.getString(defaultAddressId) ?? '',
    };
  }

  static Future<bool> isProfileCompleteCached() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(profileComplete) ?? false;
  }

  static Future<void> setProfileComplete(bool value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(profileComplete, value);
  }

  static Future<void> saveCheckoutPrefs({
    String? paymentMethodId,
    String? instructionsJson,
    int? addressIndex,
    String? orderId,
  }) async {
    final pref = await SharedPreferences.getInstance();
    if (paymentMethodId != null) {
      await pref.setString(lastPaymentMethod, paymentMethodId);
    }
    if (instructionsJson != null) {
      await pref.setString(lastDeliveryInstructions, instructionsJson);
    }
    if (addressIndex != null) {
      await pref.setInt(lastAddressIndex, addressIndex);
    }
    if (orderId != null) {
      await pref.setString(lastOrderId, orderId);
    }
  }

  static Future<String?> readLastPaymentMethodId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(lastPaymentMethod);
  }

  static Future<int?> readLastAddressIndex() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getInt(lastAddressIndex);
  }

  static Future<Map<String, dynamic>?> lastDeliveryInstructionsMap() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getString(lastDeliveryInstructions);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> readCachedUid() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('${_prefix}uid');
  }

  static Future<void> clearOnLogout() async {
    final pref = await SharedPreferences.getInstance();
    final keepKeys = {
      'selected_language_code',
      'selected_country_code',
      'notif_permission_asked',
      'notif_permission_denied',
      'location_permission_granted',
      'qg_device_id',
      'promotion_popup_last_shown_ms',
    };
    final keys = pref.getKeys().where((k) => !keepKeys.contains(k)).toList();
    for (final k in keys) {
      if (k.startsWith(_prefix) ||
          k.startsWith('notif_pref_') ||
          k.startsWith('bootstrap_home_') ||
          k.startsWith('selected_address_') ||
          k.startsWith('cache_') ||
          k.startsWith('recently_viewed_') ||
          k.startsWith('search_history') ||
          k == 'isUserExist' ||
          k == 'user_gender' ||
          k == 'pending_referral_code') {
        await pref.remove(k);
      }
    }
  }
}
