import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stable anonymous device id for coupon abuse prevention.
class DeviceIdService {
  static const _key = 'qg_device_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = 'qg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    await prefs.setString(_key, id);
    return id;
  }
}
