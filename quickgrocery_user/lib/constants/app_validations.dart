import 'package:quickgrocery/l10n/app_localizations.dart';

class AppValidations {
  static String? validateEmail(String? email, AppLocalizations l10n) {
    if (email == null || email.isEmpty) {
      return l10n.emailRequired;
    }
    final emailRegex = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    );
    if (!emailRegex.hasMatch(email)) {
      return l10n.emailInvalid;
    }
    return null;
  }

  static String? validatePassword(String? password, AppLocalizations l10n) {
    if (password == null) {
      return l10n.passwordRequired;
    }
    if (password.length < 8) {
      return l10n.passwordMinLength;
    }
    return null;
  }

  static String? validateName(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.nameRequired;
    }
    return null;
  }

  static String? validateMobile(String? value, AppLocalizations l10n) {
    if (value == null) {
      return l10n.phoneRequired;
    }
    if (value.length < 10) {
      return l10n.enterValidMobile;
    }
    return null;
  }

  static String? validateHouse(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.addressRequired;
    }
    return null;
  }

  static String? validateArea(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.areaRequired;
    }
    return null;
  }
}
