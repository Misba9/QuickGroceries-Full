import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/order/order_bill_totals.dart';
import 'package:quickgrocery/core/order/order_line_pricing.dart';

import '../../domain/order_models.dart';
import 'order_product_line_tile.dart';

/// Itemised order breakdown shown on the tracking screen.
class OrderDetailsCard extends StatelessWidget {
  const OrderDetailsCard({super.key, required this.order});

  final LiveOrder order;

  @override
  Widget build(BuildContext context) {
    final bill = OrderBillTotals.fromMap(order.billSnapshot) ??
        OrderBillTotals.fromLineTotals(
          itemsSubtotal: order.legacy.products.fold<double>(
            0,
            (sum, p) => sum + p.lineTotal,
          ),
          deliveryCharge: order.legacy.deliveryCharge,
        );

    validateOrderLinesAgainstSubtotal(
      products: order.legacy.products,
      subtotal: bill.subtotal,
      tag: 'order-details',
    );
    bill.validateAgainstItems(
      order.legacy.products.map((p) => p.lineTotal),
      tag: 'order-details',
    );
    bill.debugLog(tag: 'order-details');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppSurface.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...order.legacy.products.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OrderProductLineTile(product: p, compact: true),
            ),
          ),
          const Divider(height: 24),
          _BillLine(label: 'Subtotal', value: bill.subtotal),
          if (bill.itemSavings > 0)
            _BillLine(
              label: 'You saved on MRP',
              value: bill.itemSavings,
              valueColor: AppSurface.success,
              informational: true,
            ),
          if (bill.couponDiscount > 0)
            _BillLine(
              label: 'Coupon discount',
              value: -bill.couponDiscount,
              valueColor: AppSurface.success,
            ),
          if (bill.deliveryFee > 0)
            _BillLine(label: 'Delivery', value: bill.deliveryFee),
          if (bill.surgeFee > 0) _BillLine(label: 'Surge fee', value: bill.surgeFee),
          if (bill.handlingCharge > 0)
            _BillLine(label: 'Handling', value: bill.handlingCharge),
          if (bill.platformFee > 0)
            _BillLine(label: 'Platform fee', value: bill.platformFee),
          if (bill.tax > 0) _BillLine(label: 'Tax', value: bill.tax),
          if (bill.deliveryPartnerTip > 0)
            _BillLine(
              label: 'Delivery Partner Tip',
              value: bill.deliveryPartnerTip,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Grand total',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '₹${bill.grandTotal.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillLine extends StatelessWidget {
  const _BillLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.informational = false,
  });

  final String label;
  final double value;
  final Color? valueColor;
  final bool informational;

  @override
  Widget build(BuildContext context) {
    final prefix = informational
        ? '₹'
        : value < 0
            ? '- ₹'
            : '₹';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppSurface.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            '$prefix${value.abs().toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppSurface.text,
            ),
          ),
        ],
      ),
    );
  }
}
