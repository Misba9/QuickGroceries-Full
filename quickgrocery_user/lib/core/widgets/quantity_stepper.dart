import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Compact Zepto-style quantity stepper: `[-] N [+]`.
///
/// * Primary-color filled pill with white iconography.
/// * Animates the count via [AnimatedSwitcher] (slide + fade) so taps
///   feel responsive even on slow Firestore round-trips.
/// * Haptic tick on each interaction (`HapticFeedback.selectionClick`).
/// * Hairline ripple on the icon buttons.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    this.size = QuantityStepperSize.medium,
    this.maxQuantity,
    this.onMaxReached,
  });

  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final QuantityStepperSize size;
  final int? maxQuantity;
  final VoidCallback? onMaxReached;

  @override
  Widget build(BuildContext context) {
    final atMax = maxQuantity != null && count >= maxQuantity!;
    final dims = _dimsFor(size);

    return Material(
      color: AppColor.primary,
      borderRadius: BorderRadius.circular(dims.radius),
      elevation: 0,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: BorderRadius.circular(dims.radius),
          boxShadow: AppShadow.primaryGlow,
        ),
        child: SizedBox(
          height: dims.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconButton(
                icon: Icons.remove_rounded,
                size: dims.iconSize,
                width: dims.tapWidth,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDecrement();
                },
              ),
              SizedBox(
                width: dims.numberWidth,
                child: AnimatedSwitcher(
                  duration: AppMotion.short,
                  switchInCurve: AppMotion.spring,
                  switchOutCurve: AppMotion.standard,
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Text(
                    '$count',
                    key: ValueKey<int>(count),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: dims.numberSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
              _IconButton(
                icon: Icons.add_rounded,
                size: dims.iconSize,
                width: dims.tapWidth,
                disabled: false,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (atMax) {
                    onMaxReached?.call();
                  } else {
                    onIncrement();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Dims _dimsFor(QuantityStepperSize s) {
    switch (s) {
      case QuantityStepperSize.small:
        return const _Dims(
          height: 28,
          tapWidth: 28,
          numberWidth: 22,
          numberSize: 12,
          iconSize: 14,
          radius: 8,
        );
      case QuantityStepperSize.medium:
        return const _Dims(
          height: 32,
          tapWidth: 32,
          numberWidth: 26,
          numberSize: 13.5,
          iconSize: 16,
          radius: 10,
        );
      case QuantityStepperSize.large:
        return const _Dims(
          height: 40,
          tapWidth: 40,
          numberWidth: 32,
          numberSize: 16,
          iconSize: 20,
          radius: 12,
        );
    }
  }
}

enum QuantityStepperSize { small, medium, large }

class _Dims {
  const _Dims({
    required this.height,
    required this.tapWidth,
    required this.numberWidth,
    required this.numberSize,
    required this.iconSize,
    required this.radius,
  });

  final double height;
  final double tapWidth;
  final double numberWidth;
  final double numberSize;
  final double iconSize;
  final double radius;
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.size,
    required this.width,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final double size;
  final double width;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: width * 0.6,
      child: SizedBox(
        width: width,
        child: Icon(
          icon,
          size: size,
          color: disabled ? Colors.white54 : Colors.white,
        ),
      ),
    );
  }
}
