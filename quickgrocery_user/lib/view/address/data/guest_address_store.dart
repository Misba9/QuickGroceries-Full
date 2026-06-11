import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Temporary delivery location captured while browsing as a guest.
abstract final class GuestAddressStore {
  static const _key = 'guest_pending_address_v1';

  static Future<void> save(
    SharedPreferences prefs, {
    required String addressText,
    required String? pinCode,
    required double? latitude,
    required double? longitude,
    String? area,
    String? name,
    String? mobile,
  }) async {
    final payload = <String, dynamic>{
      'address': addressText,
      if (pinCode != null && pinCode.isNotEmpty) 'pinCode': pinCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (area != null && area.isNotEmpty) 'area': area,
      if (name != null && name.isNotEmpty) 'name': name,
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
    };
    await prefs.setString(_key, jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> load(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(_key);
  }
}
