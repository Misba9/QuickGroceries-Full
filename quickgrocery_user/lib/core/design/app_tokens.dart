import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';

/// Design tokens for the premium UI overhaul.
///
/// Use these instead of inline magic numbers — they keep spacing /
/// motion / elevation consistent across screens, and let us tweak the
/// whole app from one place.
class AppRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  /// Home hero banners — Tailwind `rounded-3xl`.
  static const double banner = 24;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

class AppShadow {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get raised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: AppColor.primary.withValues(alpha: 0.30),
          blurRadius: 18,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get dim => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
}

class AppGradients {
  static const LinearGradient flashSale = LinearGradient(
    colors: [Color(0xFFFF7A1A), Color(0xFFFF3D5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient delivery = LinearGradient(
    colors: [Color(0xFF1FB454), Color(0xFF11A04C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient brand() => LinearGradient(
        colors: [
          AppColor.primary,
          Color.lerp(AppColor.primary, Colors.orange, 0.4)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 480);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);
}

class AppBreakpoints {
  static const double phone = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
}

class AppSurface {
  static const Color background = Color(0xFFF6F7FB);
  static const Color card = Colors.white;
  static const Color subtle = Color(0xFFEFEFF3);
  static const Color border = Color(0xFFE6E6EC);
  static const Color textMuted = Color(0xFF6B6B73);
  static const Color text = Color(0xFF111114);
  static const Color textPrimary = Color(0xFF111114);
  static const Color textSecondary = Color(0xFF555560);
  static const Color success = Color(0xFF11A04C);
  static const Color danger = Color(0xFFD92D2D);
}
