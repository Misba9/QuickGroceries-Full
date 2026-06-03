import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

/// Rider earnings breakdown: delivery fee + tip.
class OrderEarningsCard extends StatelessWidget {
  const OrderEarningsCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final deliveryFee = order.deliveryFeeEarning;
    final tip = order.tipEarning;
    final total = order.totalRiderEarning;

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
          _line('Order Value', _orderValueLabel()),
          _line('Delivery Fee', '₹${deliveryFee.toStringAsFixed(0)}'),
          _line('Tip', '₹${tip.toStringAsFixed(0)}'),
          const Divider(height: 20),
          _line('Total Earnings', '₹${total.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  String _orderValueLabel() {
    final items = order.products.fold<double>(
      0,
      (s, p) => s + (p.price * p.itemCount),
    );
    return '₹${items.toStringAsFixed(0)}';
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
