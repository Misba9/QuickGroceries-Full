import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/utils/order_bill_totals.dart';

/// Order bill breakdown plus rider earnings (delivery fee + tip).
class OrderEarningsCard extends StatelessWidget {
  const OrderEarningsCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final bill = OrderBillTotals.resolve(order);
    final mrpTotal = OrderBillTotals.mrpTotal(order);
    final productDiscount = OrderBillTotals.productDiscount(order, bill);
    final couponCode = OrderBillTotals.couponCodeFromOrder(order);
    final deliveryFee = order.deliveryFeeEarning;
    final tip = order.tipEarning;
    final totalEarnings = order.totalRiderEarning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade100),
        boxShadow: [
          BoxShadow(
            color: GlobalVariables.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFE6A800)),
              const SizedBox(width: 8),
              Text(
                'Order Earnings',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (couponCode != null) ...[
            _couponBadge(couponCode, bill.couponDiscount),
            const SizedBox(height: 10),
          ],
          if (mrpTotal > 0) _line('MRP Total', mrpTotal),
          if (productDiscount > 0)
            _line('Product Discount', -productDiscount, highlight: true),
          _line('Item Total', bill.subtotal),
          if (bill.couponDiscount > 0)
            _line('Coupon Discount', -bill.couponDiscount, highlight: true),
          if (bill.deliveryFee > 0) _line('Delivery Fee', bill.deliveryFee),
          if (bill.surgeFee > 0) _line('Surge Fee', bill.surgeFee),
          if (bill.handlingCharge > 0)
            _line('Handling Fee', bill.handlingCharge),
          if (bill.platformFee > 0) _line('Platform Fee', bill.platformFee),
          if (bill.tax > 0) _line('Tax', bill.tax),
          for (final extra in bill.extraLines)
            _line(extra.label, extra.value),
          if (bill.deliveryPartnerTip > 0)
            _line('Delivery Partner Tip', bill.deliveryPartnerTip),
          const Divider(height: 20),
          _line('Grand Total', bill.grandTotal, bold: true),
          const Divider(height: 20),
          Text(
            'Your earnings',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _line('Delivery Fee', deliveryFee),
          _line('Tip', tip),
          const Divider(height: 20),
          _line('Total Earnings', totalEarnings, bold: true),
        ],
      ),
    );
  }

  Widget _couponBadge(String code, double discount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined,
              size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coupon applied',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  code,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          if (discount > 0)
            Text(
              '- ₹${discount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF059669),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(
    String label,
    double amount, {
    bool bold = false,
    bool highlight = false,
  }) {
    final prefix = amount < 0 ? '- ₹' : '₹';
    final value = amount.abs();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            '$prefix${value.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: highlight
                  ? const Color(0xFF059669)
                  : (bold ? Colors.black87 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
