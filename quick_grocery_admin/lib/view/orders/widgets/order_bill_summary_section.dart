import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/core/widgets/admin_text_selection.dart';

/// Payment breakdown — MRP, product discount, coupon, fees, grand total.
class OrderBillSummarySection extends StatelessWidget {
  const OrderBillSummarySection({
    super.key,
    required this.order,
    this.title = 'Payment summary',
    this.dense = false,
  });

  final OrderModel order;
  final String title;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bill = order.billTotals;
    final mrpTotal = order.products.fold<double>(
      0,
      (sum, p) {
        final unitMrp = p.slashedPrice > p.price + 0.01 ? p.slashedPrice : p.price;
        return sum + unitMrp * p.itemCount;
      },
    );
    final productDiscount = bill.itemSavings > 0
        ? bill.itemSavings
        : (mrpTotal - bill.subtotal).clamp(0.0, double.infinity);
    final couponDiscount = bill.couponDiscount;
    final couponCode = order.couponCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: dense ? 14 : 16,
            color: Colors.black87,
          ),
        ),
        if (couponCode != null) ...[
          SizedBox(height: dense ? 8 : 10),
          _CouponBadge(code: couponCode, discount: couponDiscount),
        ],
        SizedBox(height: dense ? 10 : 12),
        _line('MRP Total', mrpTotal),
        if (productDiscount > 0)
          _line('Product discount', -productDiscount, highlight: true),
        _line('Item total', bill.subtotal),
        if (couponDiscount > 0)
          _line('Coupon discount', -couponDiscount, highlight: true),
        if (bill.deliveryFee > 0) _line('Delivery fee', bill.deliveryFee),
        if (bill.surgeFee > 0) _line('Surge fee', bill.surgeFee),
        if (bill.handlingCharge > 0) _line('Handling fee', bill.handlingCharge),
        if (bill.platformFee > 0) _line('Platform fee', bill.platformFee),
        if (bill.tax > 0) _line('Tax', bill.tax),
        if (bill.codConvenienceFee > 0)
          _line(
            bill.codFeeDescription.isNotEmpty
                ? bill.codFeeDescription
                : 'COD Convenience Fee',
            bill.codConvenienceFee,
          ),
        if (bill.deliveryPartnerTip > 0)
          _line('Delivery partner tip', bill.deliveryPartnerTip),
        const Divider(height: 20),
        Row(
          children: [
            Text(
              'Grand total',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: dense ? 14 : 16,
              ),
            ),
            const Spacer(),
            AdminSelectableText(
              '₹${bill.grandTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: dense ? 15 : 17,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ),
        SizedBox(height: dense ? 4 : 6),
        Text(
          order.isPaid ? 'Paid online' : 'Cash on delivery',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _line(String label, double amount, {bool highlight = false}) {
    final prefix = amount < 0 ? '- ₹' : '₹';
    final value = amount.abs();
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 4 : 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: dense ? 12 : 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          AdminSelectableText(
            '$prefix${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: dense ? 12 : 13,
              color: highlight ? const Color(0xFF059669) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponBadge extends StatelessWidget {
  const _CouponBadge({required this.code, required this.discount});

  final String code;
  final double discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coupon applied',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AdminSelectableText(
                  code,
                  style: const TextStyle(
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
        ],
      ),
    );
  }
}
