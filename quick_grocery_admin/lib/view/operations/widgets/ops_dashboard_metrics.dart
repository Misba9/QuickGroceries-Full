import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';

/// Top metric cards row (selective rebuild).
class OpsDashboardMetrics extends StatelessWidget {
  const OpsDashboardMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<OpsDashboardService, int>((s) => s.pendingOrders);
    final riders = context.select<OpsDashboardService, int>((s) => s.onlineRiders);
    final delivered = context.select<OpsDashboardService, int>((s) => s.deliveredToday);
    final failed = context.select<OpsDashboardService, int>((s) => s.failedDeliveriesToday);
    final lowStock = context.select<OpsDashboardService, int>((s) => s.lowStockCount);
    final unassigned = context.select<OpsDashboardService, int>((s) => s.pendingAssignment);
    final assigned = context.select<OpsDashboardService, int>((s) => s.assignedActiveOrders);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w > 1200 ? 6 : (w > 800 ? 3 : 2);
        final cardW = (w - (cols - 1) * 12) / cols;

        final metrics = [
          _MetricSpec('Online riders', '$riders', Icons.delivery_dining_rounded,
              const Color(0xFF0E7490)),
          _MetricSpec('Pending orders', '$pending', Icons.pending_actions_rounded,
              const Color(0xFFEA580C)),
          _MetricSpec('Unassigned', '$unassigned', Icons.person_off_outlined,
              const Color(0xFFB45309)),
          _MetricSpec('Assigned live', '$assigned', Icons.assignment_ind_outlined,
              const Color(0xFF6D28D9)),
          _MetricSpec('Delivered today', '$delivered', Icons.check_circle_outline,
              const Color(0xFF047857)),
          _MetricSpec('Failed / cancelled', '$failed', Icons.error_outline,
              const Color(0xFFB91C1C)),
          _MetricSpec('Low stock alerts', '$lowStock', Icons.warning_amber_outlined,
              const Color(0xFFDC2626)),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map((m) => SizedBox(width: cardW.clamp(140, 220), child: _MetricCard(m)))
              .toList(),
        );
      },
    );
  }
}

class _MetricSpec {
  const _MetricSpec(this.label, this.value, this.icon, this.accent);
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.spec);
  final _MetricSpec spec;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        hoverColor: spec.accent.withValues(alpha: 0.06),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
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
            children: [
              Icon(spec.icon, color: spec.accent, size: 22),
              const SizedBox(height: 10),
              Text(
                spec.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                spec.label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Revenue KPI strip with INR formatting.
class OpsRevenueStrip extends StatelessWidget {
  const OpsRevenueStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final rev = context.select<OpsDashboardService, OpsRevenueSnapshot>(
      (s) => s.revenue,
    );
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final items = [
      ('Today', rev.today),
      ('Yesterday', rev.yesterday),
      ('This week', rev.weekly),
      ('This month', rev.monthly),
      ('All time', rev.total),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 700;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E293B),
                const Color(0xFF334155).withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(),
                    const SizedBox(height: 12),
                    ...items.map((e) => _row(currency, e.$1, e.$2)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _title()),
                    ...items.map(
                      (e) => Expanded(
                        child: _column(currency, e.$1, e.$2),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _title() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivered revenue',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Live · delivered orders only',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _column(NumberFormat currency, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          currency.format(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _row(NumberFormat currency, String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            currency.format(value),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
