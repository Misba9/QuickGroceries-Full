import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// App Store–readable type scale (Guideline 4.0).
///
/// Hierarchy:
/// Display 28–32 · Heading 20–24 · Section 18–20 · Body 15–16 ·
/// Button 15–16 · Secondary 13–14 · Caption 12–13.
///
/// [badge] is the only style below 12sp — numeric overlays on tiny chips.
class AppTypography {
  AppTypography._();

  static const double minReadable = 12;
  static const double buttonMinHeight = 48;

  static const double displaySize = 30;
  static const double headingSize = 22;
  static const double sectionSize = 18;
  static const double bodySize = 15;
  static const double buttonSize = 16;
  static const double secondarySize = 13;
  static const double captionSize = 12;
  static const double badgeSize = 11;

  static TextStyle poppins({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppSurface.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get display => poppins(
        fontSize: displaySize,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.4,
      );

  static TextStyle get heading => poppins(
        fontSize: headingSize,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.2,
      );

  static TextStyle get section => poppins(
        fontSize: sectionSize,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get body => poppins(
        fontSize: bodySize,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get button => poppins(
        fontSize: buttonSize,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get secondary => poppins(
        fontSize: secondarySize,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppSurface.textSecondary,
      );

  static TextStyle get caption => poppins(
        fontSize: captionSize,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppSurface.textMuted,
      );

  /// Overlay counts only (white on saturated color).
  static TextStyle get badge => poppins(
        fontSize: badgeSize,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: Colors.white,
      );

  static TextTheme textTheme() {
    final base = ThemeData.light().textTheme.apply(
          fontFamily: GoogleFonts.poppins().fontFamily,
        );

    return base.copyWith(
      displayLarge: poppins(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.5),
      displayMedium: poppins(fontSize: 28, fontWeight: FontWeight.w800, height: 1.12, letterSpacing: -0.4),
      displaySmall: poppins(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.3),
      headlineLarge: poppins(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2),
      headlineMedium: poppins(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
      headlineSmall: poppins(fontSize: 20, fontWeight: FontWeight.w700, height: 1.25),
      titleLarge: poppins(fontSize: 20, fontWeight: FontWeight.w800, height: 1.25),
      titleMedium: poppins(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
      titleSmall: poppins(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
      bodyLarge: poppins(fontSize: 16, fontWeight: FontWeight.w500, height: 1.45),
      bodyMedium: poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppSurface.textSecondary,
      ),
      bodySmall: poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppSurface.textMuted,
      ),
      labelLarge: poppins(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      labelMedium: poppins(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.15),
      labelSmall: poppins(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    );
  }
}
