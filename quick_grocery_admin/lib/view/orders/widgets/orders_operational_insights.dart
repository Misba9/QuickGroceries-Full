import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';

class OrdersOperationalInsightsSection extends StatelessWidget {
  const OrdersOperationalInsightsSection({
    super.key,
    required this.insights,
    required this.analytics,
    this.expanded = false,
  });

  final OrderOperationalInsights insights;
  final OrderAnalyticsSnapshot analytics;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Operational insights',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (insights.isPeakTraffic)
                _AlertChip(
                  label: 'Peak traffic',
                  color: const Color(0xFFEA580C),
                  icon: Icons.trending_up,
                ),
              if (analytics.delayedOrdersCount > 0) ...[
                const SizedBox(width: 8),
                _AlertChip(
                  label: '${analytics.delayedOrdersCount} delayed',
                  color: const Color(0xFFDC2626),
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 520;
              final cols = narrow
                  ? 1
                  : expanded
                      ? 2
                      : (c.maxWidth < 900 ? 2 : 4);
              final spacing = 12.0;
              final tileW = cols == 1
                  ? c.maxWidth
                  : ((c.maxWidth - spacing * (cols - 1)) / cols)
                      .clamp(140.0, 320.0);
              final items = [
                _InsightTile(
                  icon: Icons.schedule,
                  label: 'Peak ordering hour',
                  value: insights.peakOrderingHour,
                ),
                _InsightTile(
                  icon: Icons.timer,
                  label: 'Avg delivery time',
                  value: insights.avgDeliveryMinutes,
                ),
                _InsightTile(
                  icon: Icons.location_on_outlined,
                  label: 'Most active area',
                  value: insights.mostActiveArea,
                ),
                _InsightTile(
                  icon: Icons.category_outlined,
                  label: 'Top category',
                  value: insights.topCategory,
                ),
                _InsightTile(
                  icon: Icons.pending_actions,
                  label: 'Pending delivery',
                  value: '${insights.pendingDeliveryCount}',
                ),
                _InsightTile(
                  icon: Icons.two_wheeler,
                  label: 'Rider utilization',
                  value: '${insights.riderUtilizationPct.toStringAsFixed(0)}%',
                ),
                _InsightTile(
                  icon: Icons.money_off,
                  label: 'COD risk (high value)',
                  value: '${insights.codRiskCount}',
                ),
                _InsightTile(
                  icon: Icons.person_off_outlined,
                  label: 'Unassigned riders',
                  value: '${analytics.unassignedRiderCount}',
                ),
              ];
              if (narrow) {
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      items[i],
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items
                    .map((t) => SizedBox(width: tileW, child: t))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColor.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertChip extends StatelessWidget {
  const _AlertChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
