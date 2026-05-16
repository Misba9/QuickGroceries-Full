import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// Flame-shaped discount badge — top-left product image overlay.
///
/// Use [DiscountBadge.fromProduct] to auto-calculate the percentage, or pass
/// a pre-computed [percent] directly.  The badge is hidden when [percent] ≤ 0.
///
/// Matching design is used on:
///  - Product tiles: [HomeProductCard] / [ProductCardWidget]
///  - Anywhere else a product image appears
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent});

  /// Pre-computed discount percentage (whole number).  Pass 0 to hide.
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
    return ClipPath(
      clipper: _FlameBadgeClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
        decoration: const BoxDecoration(gradient: AppGradients.flashSale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'OFF',
              style: GoogleFonts.poppins(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.6,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pentagon / flame shape: flat top, straight sides, V-notch at the bottom.
class _FlameBadgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 6)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height - 6)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
