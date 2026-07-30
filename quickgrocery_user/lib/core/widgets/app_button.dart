import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';

import '../design/app_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { sm, md, lg }

/// Single source of truth for the app's CTA buttons.
///
/// Variants follow Zepto/Blinkit conventions:
///   * primary  → brand fill, raised, used for the main CTA
///   * secondary→ outlined, used for secondary actions
///   * ghost    → transparent, used inside cards / pages
///   * danger   → red fill, destructive
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final colors = _resolveColors(context, disabled);
    final padding = _resolvePadding();
    final textStyle = GoogleFonts.poppins(
      fontSize: _resolveFontSize(),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: colors.foreground,
    );

    final child = isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.foreground),
                const SizedBox(width: 8),
              ],
              Text(label, style: textStyle),
            ],
          );

    final body = AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.standard,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadii.all(AppRadii.md),
        border: colors.border == null
            ? null
            : Border.all(color: colors.border!, width: 1.2),
        boxShadow: variant == AppButtonVariant.primary && !disabled
            ? AppShadow.primaryGlow
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );

    final tappable = Material(
      color: Colors.transparent,
      borderRadius: AppRadii.all(AppRadii.md),
      child: InkWell(
        borderRadius: AppRadii.all(AppRadii.md),
        onTap: disabled ? null : onPressed,
        child: body,
      ),
    );

    if (isFullWidth) return SizedBox(width: double.infinity, child: tappable);
    return tappable;
  }

  EdgeInsets _resolvePadding() {
    switch (size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 18, vertical: 14);
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 22, vertical: 18);
    }
  }

  double _resolveFontSize() {
    switch (size) {
      case AppButtonSize.sm:
        return 12.5;
      case AppButtonSize.md:
        return 14;
      case AppButtonSize.lg:
        return 15;
    }
  }

  _BtnColors _resolveColors(BuildContext context, bool disabled) {
    final surface = AppSurface.of(context);
    if (disabled) {
      return _BtnColors(
        background: surface.subtle,
        foreground: surface.textMuted,
        border: null,
      );
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return _BtnColors(
          background: AppColor.primary,
          foreground: Colors.black,
          border: null,
        );
      case AppButtonVariant.secondary:
        return _BtnColors(
          background: surface.card,
          foreground: surface.textPrimary,
          border: surface.border,
        );
      case AppButtonVariant.ghost:
        return _BtnColors(
          background: Colors.transparent,
          foreground: surface.textPrimary,
          border: null,
        );
      case AppButtonVariant.danger:
        return _BtnColors(
          background: surface.danger,
          foreground: Colors.white,
          border: null,
        );
    }
  }
}

class _BtnColors {
  const _BtnColors({
    required this.background,
    required this.foreground,
    required this.border,
  });
  final Color background;
  final Color foreground;
  final Color? border;
}
