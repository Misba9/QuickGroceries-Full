import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';
import 'package:quickgrocery/core/theme/theme_mode_option.dart';
import 'package:quickgrocery/core/theme/theme_preference_service.dart';

/// Riverpod controller for app-wide appearance.
///
/// Mirrors [localeProvider]: reading this provider rebuilds [MaterialApp]
/// only — widgets that depend on [Theme.of] rebuild via [InheritedTheme].
class ThemeController extends Notifier<AppThemeModeOption> {
  ThemePreferenceService get _service =>
      ThemePreferenceService(ref.read(sharedPreferencesProvider));

  @override
  AppThemeModeOption build() {
    return _service.load();
  }

  ThemeMode get materialThemeMode => state.materialThemeMode;

  Future<void> setOption(AppThemeModeOption option) async {
    if (state == option) return;
    await _service.save(option);
    state = option;
  }

  Future<void> setLight() => setOption(AppThemeModeOption.light);
  Future<void> setDark() => setOption(AppThemeModeOption.dark);
  Future<void> setSystem() => setOption(AppThemeModeOption.system);

  /// Currently active brightness (accounts for System Default).
  Brightness resolvedBrightness(BuildContext context) {
    final platform = MediaQuery.platformBrightnessOf(context);
    return state.resolveBrightness(platform);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeController, AppThemeModeOption>(ThemeController.new);

final themeControllerProvider = Provider<ThemeController>((ref) {
  return ref.watch(themeModeProvider.notifier);
});
