import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';

class OrdersAnalyticsRow extends StatelessWidget {
  const OrdersAnalyticsRow({super.key, required this.analytics});

  final OrderAnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w < 520 ? 1 : (w < 900 ? 2 : (w < 1200 ? 3 : 5));
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: cols == 1 ? 3.2 : 2.15,
          children: [
            _MetricCard(
              title: 'Total Orders',
              value: '${analytics.totalOrders}',
              icon: Icons.shopping_bag_outlined,
              gradient: const [Color(0xFFFFF9E6), Color(0xFFFFF3C4)],
              accent: AppColor.primary,
              trend: analytics.ordersTrendPct,
            ),
            _MetricCard(
              title: 'Pending',
              value: '${analytics.pendingOrders}',
              icon: Icons.pending_actions_rounded,
              gradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              accent: const Color(0xFFEA580C),
            ),
            _MetricCard(
              title: 'Delivered',
              value: '${analytics.deliveredOrders}',
              icon: Icons.check_circle_outline_rounded,
              gradient: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              accent: const Color(0xFF059669),
            ),
            _MetricCard(
              title: 'Cancelled',
              value: '${analytics.cancelledOrders}',
              icon: Icons.cancel_outlined,
              gradient: const [Color(0xFFFEF2F2), Color(0xFFFECACA)],
              accent: const Color(0xFFDC2626),
            ),
            _MetricCard(
              title: 'Revenue',
              value: '₹${_formatAmount(analytics.revenue)}',
              icon: Icons.currency_rupee_rounded,
              gradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              accent: const Color(0xFF2563EB),
              trend: analytics.revenueTrendPct,
            ),
          ],
        );
      },
    );
  }

  static String _formatAmount(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.accent,
    this.trend,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
  final double? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const Spacer(),
              if (trend != null) _TrendChip(pct: trend!),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    final up = pct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: up ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 2),
          Text(
            '${pct.abs().toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: up ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
