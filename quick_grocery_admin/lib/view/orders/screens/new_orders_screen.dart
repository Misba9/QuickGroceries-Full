import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/widgets/new_orders_dispatch_queue.dart';
import 'package:quick_grocery_admin/view/orders/widgets/new_orders_live_stats.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_details_drawer.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_empty_state.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_loading_skeleton.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_manage_header.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_page_shell.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_paginated_table.dart';

/// Live dispatch hub — today's incoming orders and assignment queue.
class NewOrdersScreen extends StatefulWidget {
  const NewOrdersScreen({super.key});

  @override
  State<NewOrdersScreen> createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  Timer? _refreshTimer;
  int _ridersAvailable = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final orderSvc = context.read<OrderService>();
    orderSvc.setModulePage(OrderModulePage.newOrders);
    await orderSvc.getOrders();
    if (!mounted) return;
    final deliverySvc = context.read<DeliveryBoyService>();
    if (deliverySvc.deliveryBoys == null) {
      await deliverySvc.getDeliveryBoys();
    }
    if (!mounted) return;
    final active =
        deliverySvc.deliveryBoys?.where((b) => b.isActive).length ?? 0;
    setState(() => _ridersAvailable = active);
  }

  Future<void> _refresh() async {
    await context.read<OrderService>().getOrders();
    if (!mounted) return;
    final deliverySvc = context.read<DeliveryBoyService>();
    if (deliverySvc.deliveryBoys == null) {
      await deliverySvc.getDeliveryBoys();
    }
    if (mounted) {
      setState(() {
        _ridersAvailable =
            deliverySvc.deliveryBoys?.where((b) => b.isActive).length ?? 0;
      });
    }
  }

  void _openOrder(OrderModel order) {
    showOrderDetailsDrawer(context, order);
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<OrderService>();
    final stats = svc.newOrdersLiveStats;
    final statsWithRiders = NewOrdersLiveStats(
      newToday: stats.newToday,
      pendingAssignment: stats.pendingAssignment,
      delayed: stats.delayed,
      ridersAvailable: _ridersAvailable,
      avgDispatchMinutes: stats.avgDispatchMinutes,
    );

    return OrdersPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          OrdersManageHeader(
            page: OrderModulePage.newOrders,
            trailing: IconButton.filledTonal(
              tooltip: 'Refresh live orders',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 24),
          if (svc.isLoading && svc.orders == null)
            const OrdersAnalyticsSkeleton()
          else ...[
            LiveOrdersStatsRow(stats: statsWithRiders),
            const SizedBox(height: 24),
            PendingDispatchQueue(orders: svc.dispatchQueue, onView: _openOrder),
            const SizedBox(height: 24),
            Text(
              'Live orders (${svc.filteredOrders.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (svc.filteredOrders.isEmpty)
              const OrdersEmptyState(
                title: 'No active orders today',
                message: 'New orders will appear here in real time.',
              )
            else
              OrdersPaginatedTable(
                orders: svc.filteredOrders,
                onView: _openOrder,
                rowsPerPage: 8,
              ),
          ],
        ],
      ),
    );
  }
}
