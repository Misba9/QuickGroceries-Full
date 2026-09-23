import 'package:flutter/material.dart';

import 'package:quickgrocery/view/home/presentation/widgets/flash_sale_section.dart';

/// Local alias for the existing [FlashSaleSection] so the Categories
/// discovery page imports a single, feature-scoped surface.
///
/// Keeps the door open for category-specific flash-sale tweaks later
/// (e.g. per-category countdowns) without touching the home rail.
class FlashSaleWidget extends StatelessWidget {
  const FlashSaleWidget({
    super.key,
    this.minDiscountPercent = 25,
    this.cardMargin = const EdgeInsets.only(top: 12),
    this.heading,
    this.headingLoading = false,
    required this.heroScope,
  });

  final int minDiscountPercent;
  final EdgeInsetsGeometry cardMargin;
  final String? heading;
  final bool headingLoading;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    return FlashSaleSection(
      minDiscountPercent: minDiscountPercent,
      cardMargin: cardMargin,
      heading: heading,
      headingLoading: headingLoading,
      heroScope: heroScope,
    );
  }
}
