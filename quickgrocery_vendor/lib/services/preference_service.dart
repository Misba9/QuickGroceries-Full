import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _vendorIdKey = 'vendor_id';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Save vendor ID to SharedPreferences
  static Future<void> saveVendorId(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vendorIdKey, vendorId);
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Get stored vendor ID from SharedPreferences
  static Future<String?> getVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vendorIdKey);
  }

  /// Check if vendor is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Clear stored vendor data (logout)
  static Future<void> clearVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vendorIdKey);
    await prefs.remove(_isLoggedInKey);
  }
}

