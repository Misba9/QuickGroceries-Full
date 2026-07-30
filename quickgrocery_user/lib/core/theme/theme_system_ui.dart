import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:quickgrocery/core/theme/theme_extensions.dart';

/// Status / navigation bar styling for Android & iOS.
class ThemeSystemUi {
  ThemeSystemUi._();

  static SystemUiOverlayStyle forBrightness(
    Brightness brightness, {
    Color? navigationBarColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final nav = navigationBarColor ??
        (isDark ? AppPalette.dark.card : AppPalette.light.card);

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: nav,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static SystemUiOverlayStyle of(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.appPalette;
    return forBrightness(
      theme.brightness,
      navigationBarColor: palette.card,
    );
  }

  static void apply(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(of(context));
  }
}
