import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// Rounded discount badge — top-left product image overlay.
///
/// Pass a pre-computed [percent] directly. The badge is hidden when [percent] ≤ 0.
///
/// Used on [HomeProductCard] / [ProductCardWidget] and other product image surfaces.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent});

  /// Pre-computed discount percentage (whole number). Pass 0 to hide.
  final int percent;

  /// Calculate percentage from [price] (sale) and [originalPrice] (MRP).
  static int calculate({required double price, required double originalPrice}) {
    if (originalPrice <= 0 || price <= 0) return 0;
    if (price >= originalPrice) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.flashSale,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3D5A).withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'OFF',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
