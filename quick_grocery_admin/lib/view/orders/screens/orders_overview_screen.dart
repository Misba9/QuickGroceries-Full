import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_charts_section.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_kpi_section.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_loading_skeleton.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_operational_insights.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_overview_header.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_page_shell.dart';

/// Orders dashboard — KPIs, charts, insights (no order table).
class OrdersOverviewScreen extends StatefulWidget {
  const OrdersOverviewScreen({super.key});

  @override
  State<OrdersOverviewScreen> createState() => _OrdersOverviewScreenState();
}

class _OrdersOverviewScreenState extends State<OrdersOverviewScreen> {
  Timer? _autoRefresh;
  DateTime? _lastRefreshed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
    _autoRefresh = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    await context.read<OrderService>().getOrders();
    if (mounted) setState(() => _lastRefreshed = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<OrderService>();
    final loading = svc.isLoading && svc.orders == null;

    return OrdersPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          OrdersOverviewHeader(
            onRefresh: _load,
            lastRefreshed: _lastRefreshed,
          ),
          const SizedBox(height: 24),
          if (loading)
            const OrdersAnalyticsSkeleton()
          else ...[
            OrdersKpiSection(analytics: svc.analytics),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 1100;
                final charts = OrdersChartsSection(
                  ordersTrend: svc.ordersTrendLast7Days(),
                  revenueTrend: svc.revenueTrendLast7Days(),
                  chartHeight: wide ? 300 : 280,
                );
                final insights = OrdersOperationalInsightsSection(
                  insights: svc.operationalInsights,
                  analytics: svc.analytics,
                  expanded: wide,
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: charts),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: insights),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    charts,
                    const SizedBox(height: 24),
                    insights,
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
