import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/theme/theme_extensions.dart';

/// Typography scale used app-wide.
///
/// Built on top of `google_fonts.poppins`. Colors come from [AppPalette]
/// so Dynamic Type + theme switching stay consistent.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme({AppPalette palette = AppPalette.light}) {
    final isDark = identical(palette, AppPalette.dark);
    final base = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).textTheme.apply(
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    TextStyle make(
      double size,
      FontWeight weight, {
      double? height,
      Color? color,
      double? letter,
    }) {
      return GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? palette.textPrimary,
        letterSpacing: letter,
      );
    }

    return base.copyWith(
      displayLarge: make(28, FontWeight.w900, height: 1.05, letter: -0.5),
      displayMedium: make(24, FontWeight.w800, height: 1.1, letter: -0.4),
      displaySmall: make(22, FontWeight.w800, height: 1.15, letter: -0.3),
      headlineLarge: make(20, FontWeight.w800, height: 1.2),
      headlineMedium: make(18, FontWeight.w700, height: 1.2),
      headlineSmall: make(16, FontWeight.w700, height: 1.25),
      titleLarge: make(15, FontWeight.w800, height: 1.3),
      titleMedium: make(14, FontWeight.w700, height: 1.3),
      titleSmall: make(13, FontWeight.w700, height: 1.35),
      bodyLarge: make(14, FontWeight.w500, height: 1.45),
      bodyMedium: make(13, FontWeight.w500, height: 1.45,
          color: palette.textSecondary),
      bodySmall: make(12, FontWeight.w500, height: 1.4,
          color: palette.textMuted),
      labelLarge: make(13, FontWeight.w700, letter: 0.2),
      labelMedium: make(12, FontWeight.w700, letter: 0.2),
      labelSmall: make(11, FontWeight.w700, letter: 0.4),
    );
  }
}
