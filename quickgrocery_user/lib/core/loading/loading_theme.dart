import 'package:flutter/material.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Theme-aware colors / shadows for the category loader.
@immutable
class LoadingTheme {
  const LoadingTheme({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.imageRing,
    required this.shadow,
    required this.isDark,
  });

  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color imageRing;
  final List<BoxShadow> shadow;
  final bool isDark;

  factory LoadingTheme.of(BuildContext context) {
    final surface = AppSurface.of(context);
    final dark = context.isDarkTheme;
    return LoadingTheme(
      background: surface.scaffold,
      card: surface.card,
      textPrimary: surface.textPrimary,
      textSecondary: surface.textSecondary,
      textMuted: surface.textMuted,
      accent: AppColor.primary,
      imageRing: AppColor.primary.withValues(alpha: dark ? 0.28 : 0.16),
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.42 : 0.10),
          blurRadius: dark ? 22 : 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColor.primary.withValues(alpha: dark ? 0.16 : 0.14),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
      isDark: dark,
    );
  }

  LinearGradient get ambientGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: isDark ? 0.14 : 0.16),
          background,
          background,
        ],
        stops: const [0, 0.4, 1],
      );
}

/// Optional runtime style knobs for [CategoryLoadingWidget].
@immutable
class CategoryLoadingStyle {
  const CategoryLoadingStyle({
    this.cycleDuration,
    this.background,
    this.textColor,
  });

  final Duration? cycleDuration;
  final Color? background;
  /// When set (e.g. brand-yellow splash), overrides theme text for names.
  final Color? textColor;

  CategoryLoadingStyle copyWith({
    Duration? cycleDuration,
    Color? background,
    Color? textColor,
  }) {
    return CategoryLoadingStyle(
      cycleDuration: cycleDuration ?? this.cycleDuration,
      background: background ?? this.background,
      textColor: textColor ?? this.textColor,
    );
  }
}
