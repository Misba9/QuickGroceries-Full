import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Selectable payment option chip (Zepto-style pill).
class PaymentChip extends StatelessWidget {
  const PaymentChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final muted = !enabled;
    return Opacity(
      opacity: muted ? 0.45 : 1,
      child: AnimatedContainer(
        duration: AppMotion.short,
        curve: AppMotion.emphasized,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: InkWell(
            onTap: muted
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Ink(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                color: selected
                    ? AppColor.primary.withValues(alpha: 0.14)
                    : AppSurface.of(context).card,
                border: Border.all(
                  color: selected
                      ? AppColor.primary
                      : AppSurface.of(context).border,
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected ? AppShadow.dim : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? AppColor.primary
                        : AppSurface.of(context).textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppSurface.of(context).text
                          : AppSurface.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
