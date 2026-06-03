import 'package:flutter/material.dart';

import 'app_color.dart';

/// High-contrast form and text themes for the vendor app (WCAG-friendly).
class VendorAppTheme {
  VendorAppTheme._();

  static const _radius = 12.0;

  static ThemeData light() {
    const surface = Color(0xFFF5F5F7);
    const onSurface = Color(0xFF1C1C1E);
    const onSurfaceVariant = Color(0xFF48484A);
    const hint = Color(0xFF6B7280);
    const border = Color(0xFF9CA3AF);
    const fill = Colors.white;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.primary,
      brightness: Brightness.light,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: _textTheme(onSurface, onSurfaceVariant),
      inputDecorationTheme: _inputDecoration(
        fill: fill,
        label: const Color(0xFF111827),
        hint: hint,
        border: border,
        focused: AppColor.primary,
        error: const Color(0xFFDC2626),
        isDark: false,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: fill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const surface = Color(0xFF121212);
    const onSurface = Color(0xFFF5F5F5);
    const onSurfaceVariant = Color(0xFFB0B0B5);
    const hint = Color(0xFF9CA3AF);
    const border = Color(0xFF6B7280);
    const fill = Color(0xFF1E1E1E);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.primary,
      brightness: Brightness.dark,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: _textTheme(onSurface, onSurfaceVariant),
      inputDecorationTheme: _inputDecoration(
        fill: fill,
        label: onSurface,
        hint: hint,
        border: border,
        focused: AppColor.primary,
        error: const Color(0xFFEF4444),
        isDark: true,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: fill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade700),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondary,
        height: 1.35,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }

  static InputDecorationTheme _inputDecoration({
    required Color fill,
    required Color label,
    required Color hint,
    required Color border,
    required Color focused,
    required Color error,
    required bool isDark,
  }) {
    final borderRadius = BorderRadius.circular(_radius);
    final enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: border, width: 1.25),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: label,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: isDark ? AppColor.primary : const Color(0xFF374151),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(
        color: hint,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      helperStyle: TextStyle(
        color: hint,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: TextStyle(
        color: error,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return error;
        if (states.contains(WidgetState.focused)) {
          return isDark ? AppColor.primary : const Color(0xFF374151);
        }
        return const Color(0xFF4B5563);
      }),
      enabledBorder: enabledBorder,
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: border.withValues(alpha: 0.5),
          width: 1.25,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: focused, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: error, width: 1.25),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: error, width: 2),
      ),
    );
  }
}
