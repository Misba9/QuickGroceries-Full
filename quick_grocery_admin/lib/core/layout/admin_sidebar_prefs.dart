import 'package:shared_preferences/shared_preferences.dart';

/// Persists desktop sidebar collapsed state (SharedPreferences → localStorage on web).
abstract final class AdminSidebarPrefs {
  static const _collapsedKey = 'admin_sidebar_collapsed';

  static Future<bool> loadCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_collapsedKey) ?? false;
  }

  static Future<void> saveCollapsed(bool collapsed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collapsedKey, collapsed);
  }
}
