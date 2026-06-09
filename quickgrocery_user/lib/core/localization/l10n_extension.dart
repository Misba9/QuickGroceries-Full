import 'package:flutter/material.dart';
import 'package:quickgrocery/l10n/app_localizations.dart';

/// Short access to generated [AppLocalizations] for the current locale.
extension AppL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Lookup when only a [Locale] is available (no [BuildContext]).
AppLocalizations lookupL10n(Locale locale) =>
    lookupAppLocalizations(locale);
