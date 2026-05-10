import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  Locale _currentLocale = const Locale('en', 'US');

  Locale get currentLocale => _currentLocale;

  LanguageService() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final pref = await SharedPreferences.getInstance();
    final savedLanguageCode = pref.getString('selected_language_code');
    final savedCountryCode = pref.getString('selected_country_code');

    if (savedLanguageCode != null && savedCountryCode != null) {
      _currentLocale = Locale(savedLanguageCode, savedCountryCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(Locale locale, BuildContext context) async {
    _currentLocale = locale;

    final pref = await SharedPreferences.getInstance();
    await pref.setString('selected_language_code', locale.languageCode);
    await pref.setString('selected_country_code', locale.countryCode ?? '');

    // Update the locale in EasyLocalization
    await context.setLocale(locale);

    // Notify listeners to trigger rebuild
    notifyListeners();
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'te':
        return 'తెలుగు';
      default:
        return 'English';
    }
  }

  List<Map<String, dynamic>> getAvailableLanguages() {
    return [
      {'code': 'en', 'country': 'US', 'name': 'English'},
      {'code': 'hi', 'country': 'IN', 'name': 'हिंदी'},
      {'code': 'te', 'country': 'IN', 'name': 'తెలుగు'},
    ];
  }
}
