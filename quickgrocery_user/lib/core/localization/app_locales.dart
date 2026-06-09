import 'package:flutter/material.dart';

/// Central locale configuration — asset file names must match
/// `assets/translations/{languageCode}-{countryCode}.json`.
class AppLocales {
  AppLocales._();

  static Locale fallback = const Locale('en');

  /// Supported app languages (English, Hindi, Telugu, Urdu).
  /// Country codes are kept for SharedPreferences compatibility; gen_l10n uses
  /// language-only locale tags (en, hi, te, ur).
  static const List<Locale> supported = [
    Locale('en'),
    Locale('hi'),
    Locale('te'),
    Locale('ur'),
  ];

  static const List<String> displayNames = [
    'English',
    'हिंदी',
    'తెలుగు',
    'اردو',
  ];

  static bool isRtl(Locale locale) => locale.languageCode == 'ur';

  static String assetFileName(Locale locale) => '${locale.languageCode}.arb';

  /// Maps saved / requested locale to a supported locale, else [fallback].
  static Locale resolve(Locale? locale) {
    if (locale == null) return fallback;

    for (final supportedLocale in supported) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    return fallback;
  }

  static Locale fromPreference(String? languageCode, String? countryCode) {
    if (languageCode == null || languageCode.isEmpty) return fallback;
    return resolve(Locale(languageCode));
  }

  /// Country code stored in SharedPreferences for each language.
  static String preferenceCountryCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'US';
      case 'hi':
      case 'te':
      case 'ur':
        return 'IN';
      default:
        return 'US';
    }
  }
}
