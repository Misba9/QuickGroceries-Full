import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';

class OrdersKpiSection extends StatelessWidget {
  const OrdersKpiSection({super.key, required this.analytics});

  final OrderAnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric(
        title: 'Total Orders',
        value: '${analytics.totalOrders}',
        icon: Icons.shopping_bag_outlined,
        accent: AppColor.primary,
        trend: analytics.ordersTrendPct,
      ),
      _Metric(
        title: 'Active Orders',
        value: '${analytics.pendingOrders}',
        icon: Icons.local_shipping_outlined,
        accent: const Color(0xFFEA580C),
      ),
      _Metric(
        title: 'Delivered',
        value: '${analytics.deliveredOrders}',
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF059669),
      ),
      _Metric(
        title: 'Cancelled',
        value: '${analytics.cancelledOrders}',
        icon: Icons.cancel_outlined,
        accent: const Color(0xFFDC2626),
      ),
      _Metric(
        title: 'Revenue Today',
        value: '₹${_compact(analytics.revenueToday)}',
        icon: Icons.today_outlined,
        accent: const Color(0xFF2563EB),
      ),
      _Metric(
        title: 'Total Revenue',
        value: '₹${_compact(analytics.revenue)}',
        icon: Icons.currency_rupee,
        accent: const Color(0xFF7C3AED),
        trend: analytics.revenueTrendPct,
      ),
      _Metric(
        title: 'Avg Delivery',
        value: '${analytics.avgDeliveryMinutes.toStringAsFixed(0)}m',
        icon: Icons.timer_outlined,
        accent: const Color(0xFF0891B2),
      ),
      _Metric(
        title: 'COD %',
        value: '${analytics.codPct.toStringAsFixed(0)}%',
        icon: Icons.payments_outlined,
        accent: const Color(0xFFD97706),
      ),
      _Metric(
        title: 'Online Pay %',
        value: '${analytics.onlinePaymentPct.toStringAsFixed(0)}%',
        icon: Icons.credit_card_outlined,
        accent: const Color(0xFF4F46E5),
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map(
            (m) => SizedBox(
              width: 240,
              child: _AnalyticsCard(metric: m),
            ),
          )
          .toList(),
    );
  }

  static String _compact(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }
}

class _Metric {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.trend,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final double? trend;
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric.icon, color: metric.accent, size: 20),
              ),
              const Spacer(),
              if (metric.trend != null)
                _TrendBadge(pct: metric.trend!),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    final up = pct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (up ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: up ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
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
