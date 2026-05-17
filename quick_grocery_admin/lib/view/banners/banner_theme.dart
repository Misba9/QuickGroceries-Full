import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';

/// Shared visual tokens for Banner Management (Shopify / Blinkit–style admin).
abstract final class BannerTheme {
  static const Color pageBackground = Color(0xFFF4F5F7);
  static const Color cardBackground = Colors.white;
  static const Color accent = AppColor.primary;

  static BoxDecoration cardDecoration({bool hovered = false}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: hovered ? accent.withValues(alpha: 0.45) : const Color(0xFFE8EAED),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: hovered ? 0.06 : 0.03),
          blurRadius: hovered ? 18 : 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static InputDecoration fieldDecoration({
    required String label,
    String? hint,
    String? helper,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFFAFAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8EAED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8EAED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static ButtonStyle outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1A1A1A),
      side: const BorderSide(color: Color(0xFFE8EAED)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
