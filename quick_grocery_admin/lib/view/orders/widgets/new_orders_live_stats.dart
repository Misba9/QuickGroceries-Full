import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart'
    show NewOrdersLiveStats;

/// KPI strip for the New Orders dispatch page.
class LiveOrdersStatsRow extends StatelessWidget {
  const LiveOrdersStatsRow({super.key, required this.stats});

  final NewOrdersLiveStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        label: 'New Orders',
        value: '${stats.newToday}',
        icon: Icons.fiber_new_rounded,
        accent: AppColor.primary,
      ),
      _StatCard(
        label: 'Pending Assignment',
        value: '${stats.pendingAssignment}',
        icon: Icons.pending_actions,
        accent: const Color(0xFFEA580C),
      ),
      _StatCard(
        label: 'Delayed Orders',
        value: '${stats.delayed}',
        icon: Icons.warning_amber_rounded,
        accent: const Color(0xFFDC2626),
      ),
      _StatCard(
        label: 'Riders Available',
        value: stats.ridersAvailable > 0 ? '${stats.ridersAvailable}' : '—',
        icon: Icons.two_wheeler,
        accent: const Color(0xFF2563EB),
      ),
      _StatCard(
        label: 'Avg Dispatch Time',
        value: stats.avgDispatchMinutes,
        icon: Icons.timer_outlined,
        accent: const Color(0xFF0891B2),
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((c) => SizedBox(width: 240, child: c)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

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
          Icon(icon, color: accent, size: 22),
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
