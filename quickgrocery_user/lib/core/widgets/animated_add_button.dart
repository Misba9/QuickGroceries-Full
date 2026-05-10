import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/quantity_stepper.dart';

/// "ADD ↔ stepper" toggle used on grocery cards.
///
/// * **count == 0** → outlined ADD button (white surface, primary outline).
/// * **count >  0** → filled [QuantityStepper].
///
/// Swap is animated via [AnimatedSwitcher] with a soft scale + fade so
/// the card feels alive when items are added or removed.
class AnimatedAddButton extends StatelessWidget {
  const AnimatedAddButton({
    super.key,
    required this.count,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.size = QuantityStepperSize.medium,
    this.maxQuantity,
  });

  final int count;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final QuantityStepperSize size;
  final int? maxQuantity;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.short,
      curve: AppMotion.emphasized,
      alignment: Alignment.centerRight,
      child: AnimatedSwitcher(
        duration: AppMotion.short,
        switchInCurve: AppMotion.spring,
        switchOutCurve: AppMotion.standard,
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: count <= 0
            ? _AddPill(
                key: const ValueKey('add'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAdd();
                },
                size: size,
              )
            : QuantityStepper(
                key: const ValueKey('stepper'),
                count: count,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                size: size,
                maxQuantity: maxQuantity,
              ),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({super.key, required this.onTap, required this.size});

  final VoidCallback onTap;
  final QuantityStepperSize size;

  @override
  Widget build(BuildContext context) {
    final dims = _AddDims.from(size);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(dims.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(dims.radius),
        onTap: onTap,
        child: Ink(
          height: dims.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(dims.radius),
            border: Border.all(color: AppColor.primary.withValues(alpha: 0.55)),
            boxShadow: AppShadow.dim,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dims.padding),
            child: Center(
              child: Text(
                'ADD',
                style: GoogleFonts.poppins(
                  fontSize: dims.fontSize,
                  fontWeight: FontWeight.w800,
                  color: AppColor.primary,
                  letterSpacing: 0.6,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddDims {
  const _AddDims({
    required this.height,
    required this.padding,
    required this.radius,
    required this.fontSize,
  });

  final double height;
  final double padding;
  final double radius;
  final double fontSize;

  factory _AddDims.from(QuantityStepperSize s) {
    switch (s) {
      case QuantityStepperSize.small:
        return const _AddDims(height: 28, padding: 14, radius: 8, fontSize: 11.5);
      case QuantityStepperSize.medium:
        return const _AddDims(height: 32, padding: 18, radius: 10, fontSize: 12.5);
      case QuantityStepperSize.large:
        return const _AddDims(height: 40, padding: 22, radius: 12, fontSize: 14);
    }
  }
}
