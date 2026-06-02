import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';

/// Branded placeholder when a product image is missing or fails to load.
class ProductBrandedPlaceholder extends StatelessWidget {
  const ProductBrandedPlaceholder({
    super.key,
    this.width,
    this.height,
    this.compact = false,
  });

  final double? width;
  final double? height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.primary.withValues(alpha: 0.12),
            Colors.grey.shade100,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: compact ? 48 : 72,
            height: compact ? 48 : 72,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.shopping_basket_outlined,
              size: compact ? 40 : 56,
              color: AppColor.primary.withValues(alpha: 0.7),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Text(
              'Quick Groceries',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Image coming soon',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
