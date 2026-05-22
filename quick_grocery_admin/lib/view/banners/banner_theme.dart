import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';

/// Shared visual tokens for Banner Management (Shopify / Blinkit–style admin).
abstract final class BannerTheme {
  static const Color pageBackground = Color(0xFFF4F5F7);
  static const Color cardBackground = Colors.white;
  static const Color accent = AppColor.primary;

  /// Uniform border color — required when using [BorderRadius] on decorations.
  static const Color borderColor = Color(0xFFE5E7EB);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(12));

  static const OutlineInputBorder outlineBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: borderColor),
  );

  static BoxDecoration cardDecoration({bool hovered = false}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: cardRadius,
      border: Border.all(
        color: hovered ? accent.withValues(alpha: 0.45) : borderColor,
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
      border: outlineBorder,
      enabledBorder: outlineBorder,
      focusedBorder: outlineBorder,
      errorBorder: outlineBorder,
      focusedErrorBorder: outlineBorder,
      disabledBorder: outlineBorder,
    );
  }

  /// Minimum tap height for web admin buttons (avoids RenderFlex overflow).
  static const Size buttonMinSize = Size(64, 52);

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      minimumSize: buttonMinSize,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
    );
  }

  static ButtonStyle outlineButtonStyle({Color? sideColor}) {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1A1A1A),
      side: BorderSide(color: sideColor ?? borderColor),
      minimumSize: buttonMinSize,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: const RoundedRectangleBorder(borderRadius: fieldRadius),
    );
  }
}
