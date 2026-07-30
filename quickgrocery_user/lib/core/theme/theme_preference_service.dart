import 'package:shared_preferences/shared_preferences.dart';

import 'theme_mode_option.dart';

/// Persists the user's appearance preference forever.
class ThemePreferenceService {
  ThemePreferenceService(this._prefs);

  static const preferenceKey = 'theme_mode';

  final SharedPreferences _prefs;

  AppThemeModeOption load() {
    final raw = _prefs.getString(preferenceKey);
    return AppThemeModeOptionX.fromStorage(raw);
  }

  Future<void> save(AppThemeModeOption option) async {
    await _prefs.setString(preferenceKey, option.storageValue);
  }
}
