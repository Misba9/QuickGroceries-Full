import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/theme/theme_extensions.dart';

/// Central brand + semantic color access for the User App.
///
/// Prefer [AppPalette] via `AppSurface.of(context)` or `context.appPalette`
/// inside widgets. Use this file for brand constants and non-context helpers.
class AppColors {
  AppColors._();

  /// Brand primary (amber) — intentional hardcoded brand color.
  static const Color primary = AppColor.primary;

  /// Light / dark palette snapshots (prefer context-aware [of]).
  static const AppPalette light = AppPalette.light;
  static const AppPalette dark = AppPalette.dark;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

  static ColorScheme schemeOf(BuildContext context) =>
      Theme.of(context).colorScheme;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
