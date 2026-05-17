import 'package:shared_preferences/shared_preferences.dart';

class DeliverySessionPrefs {
  static const _idKey = 'deliveryBoyId';
  static const _sessionKey = 'session_version';
  static const _forceKey = 'force_password_change';

  static Future<void> saveLogin({
    required String deliveryBoyId,
    required int sessionVersion,
    required bool forcePasswordChange,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, deliveryBoyId);
    await prefs.setInt(_sessionKey, sessionVersion);
    await prefs.setBool(_forceKey, forcePasswordChange);
  }

  static Future<String?> deliveryBoyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  static Future<int?> sessionVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionKey);
  }

  static Future<bool> forcePasswordChange() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_forceKey) ?? false;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
    await prefs.remove(_sessionKey);
    await prefs.remove(_forceKey);
  }
}
