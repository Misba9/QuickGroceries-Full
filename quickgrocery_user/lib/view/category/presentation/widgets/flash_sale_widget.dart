import 'package:flutter/material.dart';

import 'package:quickgrocery/view/home/presentation/widgets/flash_sale_section.dart';

/// Local alias for the existing [FlashSaleSection] so the Categories
/// discovery page imports a single, feature-scoped surface.
///
/// Keeps the door open for category-specific flash-sale tweaks later
/// (e.g. per-category countdowns) without touching the home rail.
class FlashSaleWidget extends StatelessWidget {
  const FlashSaleWidget({super.key, this.minDiscountPercent = 25});

  final int minDiscountPercent;

  @override
  Widget build(BuildContext context) {
    return FlashSaleSection(minDiscountPercent: minDiscountPercent);
  }
}
