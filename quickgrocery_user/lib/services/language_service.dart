import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/localization/app_locales.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  Locale _currentLocale = AppLocales.fallback;

  Locale get currentLocale => _currentLocale;

  bool get isRtl => AppLocales.isRtl(_currentLocale);

  LanguageService() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final pref = await SharedPreferences.getInstance();
    final savedLanguageCode = pref.getString('selected_language_code');
    final savedCountryCode = pref.getString('selected_country_code');

    _currentLocale = AppLocales.fromPreference(
      savedLanguageCode,
      savedCountryCode,
    );
    notifyListeners();
  }

  Future<void> changeLanguage(Locale locale) async {
    final resolved = AppLocales.resolve(locale);
    if (_currentLocale == resolved) return;

    final pref = await SharedPreferences.getInstance();

    try {
      _currentLocale = resolved;
      await pref.setString('selected_language_code', resolved.languageCode);
      await pref.setString(
        'selected_country_code',
        resolved.countryCode ?? AppLocales.fallback.countryCode!,
      );

      final rootContext = rootNavigatorKey.currentContext;
      if (rootContext != null && rootContext.mounted) {
        await rootContext.setLocale(resolved);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[Language] setLocale(${AppLocales.assetFileName(resolved)}) failed: $e\n$st',
        );
      }
      await _applyFallbackLocale(pref);
    }

    notifyListeners();
  }

  Future<void> _applyFallbackLocale(SharedPreferences pref) async {
    _currentLocale = AppLocales.fallback;
    await pref.setString('selected_language_code', AppLocales.fallback.languageCode);
    await pref.setString(
      'selected_country_code',
      AppLocales.fallback.countryCode ?? 'US',
    );

    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      try {
        await rootContext.setLocale(AppLocales.fallback);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Language] fallback setLocale failed: $e');
        }
      }
    }
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'te':
        return 'తెలుగు';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }

  List<Map<String, dynamic>> getAvailableLanguages() {
    return const [
      {'code': 'en', 'country': 'US', 'name': 'English'},
      {'code': 'hi', 'country': 'IN', 'name': 'हिंदी'},
      {'code': 'te', 'country': 'IN', 'name': 'తెలుగు'},
      {'code': 'ur', 'country': 'IN', 'name': 'اردو'},
    ];
  }
}
