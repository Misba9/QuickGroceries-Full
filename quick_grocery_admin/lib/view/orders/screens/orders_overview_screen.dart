import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_details_drawer.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_charts_section.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_kpi_section.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_loading_skeleton.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_operational_insights.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_overview_header.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_page_shell.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_recent_section.dart';

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

  void _openOrder(OrderModel order) => showOrderDetailsDrawer(context, order);

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
            OrdersChartsSection(
              ordersTrend: svc.ordersTrendLast7Days(),
              revenueTrend: svc.revenueTrendLast7Days(),
            ),
            const SizedBox(height: 24),
            OrdersOperationalInsightsSection(
              insights: svc.operationalInsights,
              analytics: svc.analytics,
            ),
            const SizedBox(height: 24),
            OrdersRecentSection(
              orders: svc.recentOrdersForOverview,
              onView: _openOrder,
            ),
          ],
        ],
      ),
    );
  }
}
