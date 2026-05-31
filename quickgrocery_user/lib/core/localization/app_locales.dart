import 'package:flutter/material.dart';

/// Central locale configuration — asset file names must match
/// `assets/translations/{languageCode}-{countryCode}.json`.
class AppLocales {
  AppLocales._();

  static const Locale fallback = Locale('en', 'US');

  /// Supported app languages (English, Hindi, Telugu, Urdu).
  static const List<Locale> supported = [
    Locale('en', 'US'),
    Locale('hi', 'IN'),
    Locale('te', 'IN'),
    Locale('ur', 'IN'),
  ];

  static const List<String> displayNames = [
    'English',
    'हिंदी',
    'తెలుగు',
    'اردو',
  ];

  static bool isRtl(Locale locale) => locale.languageCode == 'ur';

  static String assetFileName(Locale locale) =>
      '${locale.languageCode}-${locale.countryCode ?? ''}.json';

  /// Maps saved / requested locale to a supported locale, else [fallback].
  static Locale resolve(Locale? locale) {
    if (locale == null) return fallback;

    for (final supportedLocale in supported) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return supportedLocale;
      }
    }

    for (final supportedLocale in supported) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    return fallback;
  }

  static Locale fromPreference(String? languageCode, String? countryCode) {
    if (languageCode == null || languageCode.isEmpty) return fallback;
    return resolve(Locale(languageCode, countryCode ?? fallback.countryCode));
  }
}
