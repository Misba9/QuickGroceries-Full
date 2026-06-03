import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

/// Large payment badge — online paid vs COD to collect.
class PaymentStatusCard extends StatelessWidget {
  const PaymentStatusCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final p = order.payment;
    final online = p.isOnlinePaid;
    final collected = p.isPaymentCollected;
    final amount = p.orderTotal;

    final Color bg;
    final Color fg;
    final IconData icon;
    final String title;
    final String subtitle;

    if (online) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      icon = Icons.verified_rounded;
      title = 'ONLINE PAID ✅';
      subtitle = 'Amount paid ₹${p.displayPaidAmount.toStringAsFixed(0)}';
    } else if (collected) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      icon = Icons.check_circle_rounded;
      title = 'PAID';
      final via = p.collectionMethod.isNotEmpty
          ? p.collectionMethod.toUpperCase()
          : 'COD';
      subtitle = '₹${p.displayPaidAmount.toStringAsFixed(0)} via $via';
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
      icon = Icons.payments_rounded;
      title = 'COD TO COLLECT';
      subtitle = '₹${amount.toStringAsFixed(0)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: fg,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
                if (online && order.razorpayPaymentId.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Txn ${order.razorpayPaymentId.length > 12 ? order.razorpayPaymentId.substring(0, 12) : order.razorpayPaymentId}…',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
