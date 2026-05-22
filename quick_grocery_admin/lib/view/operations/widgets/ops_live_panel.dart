import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/widgets/admin_list_tile.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';

/// Live ops counters + recent orders + activity feed (Firestore streams).
class OpsLivePanel extends StatelessWidget {
  const OpsLivePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<OpsDashboardService>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric('Pending orders', '${ops.pendingOrders}', Icons.pending_actions),
            _metric('Revenue today', currency.format(ops.revenueToday), Icons.payments),
            _metric('Online riders', '${ops.onlineRiders}', Icons.delivery_dining),
            _metric('Low / OOS', '${ops.lowStockCount}', Icons.warning_amber_outlined),
            _metric('Delivered today', '${ops.deliveredToday}', Icons.check_circle_outline),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Live order queue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (ops.liveOrders.isEmpty)
          Text('No pending orders', style: TextStyle(color: Colors.grey.shade600))
        else
          ...ops.liveOrders.take(6).map((o) {
            final id = o['id']?.toString() ?? '';
            final name = o['customer_name']?.toString() ?? 'Customer';
            final status = o['order_status']?.toString() ?? o['status']?.toString() ?? '';
            return AdminListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColor.primary.withValues(alpha: 0.12),
                child: Text('#${id.length > 4 ? id.substring(id.length - 4) : id}'),
              ),
              title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(status, maxLines: 1),
            );
          }),
        const SizedBox(height: 16),
        Text(
          'Recent activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (ops.recentActivities.isEmpty)
          Text('No activity yet', style: TextStyle(color: Colors.grey.shade600))
        else
          ...ops.recentActivities.take(8).map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                a['summary']?.toString() ?? a['action']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColor.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
