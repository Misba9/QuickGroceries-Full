import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _vendorIdKey = 'vendor_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _sessionVersionKey = 'session_version';
  static const String _forcePasswordChangeKey = 'force_password_change';

  static Future<void> saveVendorId(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vendorIdKey, vendorId);
    await prefs.setBool(_isLoggedInKey, true);
  }

  static Future<String?> getVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vendorIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> saveSessionVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionVersionKey, version);
  }

  static Future<int?> getSessionVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionVersionKey);
  }

  static Future<void> setForcePasswordChange(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forcePasswordChangeKey, value);
  }

  static Future<bool> getForcePasswordChange() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_forcePasswordChangeKey) ?? false;
  }

  static Future<void> clearVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vendorIdKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_sessionVersionKey);
    await prefs.remove(_forcePasswordChangeKey);
  }
}
