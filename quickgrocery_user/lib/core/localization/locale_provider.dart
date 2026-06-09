import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/localization/app_locales.dart';
import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';

/// Single source of truth for the active app [Locale].
///
/// Persisted in SharedPreferences; updating [state] rebuilds [MaterialApp]
/// and every widget that reads [AppLocalizations.of(context)].
class AppLocaleController extends Notifier<Locale> {
  static const _languageKey = 'selected_language_code';
  static const _countryKey = 'selected_country_code';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppLocales.fromPreference(
      prefs.getString(_languageKey),
      prefs.getString(_countryKey),
    );
  }

  bool get isRtl => AppLocales.isRtl(state);

  Future<void> setLocale(Locale locale) async {
    final resolved = AppLocales.resolve(locale);
    if (state.languageCode == resolved.languageCode) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final countryCode = AppLocales.preferenceCountryCode(resolved.languageCode);
    await prefs.setString(_languageKey, resolved.languageCode);
    await prefs.setString(_countryKey, countryCode);
    state = resolved;
  }

  List<Map<String, String>> get availableLanguages => const [
        {'code': 'en', 'country': 'US', 'name': 'English'},
        {'code': 'hi', 'country': 'IN', 'name': 'हिंदी'},
        {'code': 'te', 'country': 'IN', 'name': 'తెలుగు'},
        {'code': 'ur', 'country': 'IN', 'name': 'اردو'},
      ];
}

final localeProvider = NotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

final localeControllerProvider = Provider<AppLocaleController>((ref) {
  return ref.watch(localeProvider.notifier);
});
