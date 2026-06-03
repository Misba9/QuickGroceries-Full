import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/order/order_line_display.dart';
import 'package:quickgrocery/core/order/order_line_pricing.dart';
import 'package:quickgrocery/models/order_model.dart';

/// Order snapshot line: purchased price primary, MRP strikethrough when discounted.
class OrderProductLineTile extends StatelessWidget {
  const OrderProductLineTile({
    super.key,
    required this.product,
    this.compact = false,
  });

  final ProductItem product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pricing = OrderLinePricing.fromProductItem(product);
    final paidLineFmt = formatOrderMoney(pricing.lineTotal);
    final mrpLineFmt = formatOrderMoney(pricing.mrp * pricing.quantity);
    final paidUnitFmt = formatOrderMoney(pricing.pricePaid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: GoogleFonts.poppins(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          orderLineQtyDetail(product),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppSurface.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        if (pricing.hasDiscount)
          Text(
            '₹$mrpLineFmt',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppSurface.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          '₹$paidLineFmt',
          style: GoogleFonts.poppins(
            fontSize: compact ? 13 : 14,
            color: AppSurface.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${pricing.quantity} × ₹$paidUnitFmt',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: AppSurface.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (pricing.hasDiscount) ...[
          const SizedBox(height: 6),
          _SavingsBadge(label: pricing.savingsLabel),
        ],
      ],
    );
  }
}

class _SavingsBadge extends StatelessWidget {
  const _SavingsBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
