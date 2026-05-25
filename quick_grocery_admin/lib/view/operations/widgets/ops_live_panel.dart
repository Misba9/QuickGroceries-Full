import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/operations/widgets/ops_activity_feed.dart';
import 'package:quick_grocery_admin/view/operations/widgets/ops_dashboard_charts.dart';
import 'package:quick_grocery_admin/view/operations/widgets/ops_dashboard_metrics.dart';
import 'package:quick_grocery_admin/view/operations/widgets/ops_live_order_queue.dart';

/// Real-time ops dashboard: revenue, metrics, queue, charts, activity.
class OpsLivePanel extends StatelessWidget {
  const OpsLivePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OpsRevenueStrip(),
        const SizedBox(height: 16),
        const OpsDashboardMetrics(),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 1100;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: OpsLiveOrderQueue()),
                  const SizedBox(width: 16),
                  const Expanded(flex: 2, child: OpsActivityFeed()),
                ],
              );
            }
            return const Column(
              children: [
                OpsLiveOrderQueue(),
                SizedBox(height: 16),
                OpsActivityFeed(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const OpsDashboardCharts(),
      ],
    );
  }
}
