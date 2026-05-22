import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/style/app_color.dart';

class RefundStats {
  const RefundStats({
    required this.totalCancelled,
    required this.refundFlagged,
    required this.pendingReview,
    required this.codRefunds,
  });

  final int totalCancelled;
  final int refundFlagged;
  final int pendingReview;
  final int codRefunds;
}

class RefundStatsRow extends StatelessWidget {
  const RefundStatsRow({super.key, required this.stats});

  final RefundStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Card('Cancelled orders', '${stats.totalCancelled}', Icons.cancel_outlined,
          const Color(0xFFDC2626)),
      _Card('Refund flagged', '${stats.refundFlagged}',
          Icons.currency_exchange, const Color(0xFFB45309)),
      _Card('Pending review', '${stats.pendingReview}', Icons.rate_review_outlined,
          AppColor.primary),
      _Card('COD refunds', '${stats.codRefunds}', Icons.payments_outlined,
          const Color(0xFF2563EB)),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((c) => SizedBox(width: 240, child: c)).toList(),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
