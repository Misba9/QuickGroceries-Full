import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Horizontal delivery slot pill with express lightning accent.
class DeliverySlotChip extends StatelessWidget {
  const DeliverySlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isExpress,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isExpress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.emphasized,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              gradient: selected && isExpress ? AppGradients.flashSale : null,
              color: selected && !isExpress
                  ? AppColor.primary.withValues(alpha: 0.14)
                  : !selected
                      ? Colors.white
                      : null,
              border: Border.all(
                color: selected
                    ? (isExpress ? Colors.transparent : AppColor.primary)
                    : AppSurface.of(context).border,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected ? AppShadow.dim : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExpress) ...[
                  Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: selected ? Colors.white : Color(0xFFE17500),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? (isExpress ? Colors.white : AppSurface.of(context).text)
                        : AppSurface.of(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
