import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/services/rider_assignment_client.dart';
import 'package:quick_grocery_admin/view/orders/widgets/assign_rider_dialog.dart';
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
  int _ridersAvailable = 0;
  final _riderClient = RiderAssignmentClient();
  bool _batchAssigning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
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
    final active = deliverySvc.deliveryBoys
            ?.where((b) => b.isActive && b.isOnline)
            .length ??
        0;
    setState(() => _ridersAvailable = active);
  }

  Future<void> _refreshRiders() async {
    final deliverySvc = context.read<DeliveryBoyService>();
    await deliverySvc.getDeliveryBoys();
    if (mounted) {
      setState(() {
        _ridersAvailable =
            deliverySvc.deliveryBoys?.where((b) => b.isActive && b.isOnline).length ?? 0;
      });
    }
  }

  Future<void> _assignRider(OrderModel order) async {
    await AssignRiderDialog.show(context, order: order, client: _riderClient);
  }

  Future<void> _autoAssignRider(OrderModel order) async {
    try {
      final r = await _riderClient.autoAssign(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auto-assigned ${r.riderName} (${r.distanceKm.toStringAsFixed(1)} km)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(RiderAssignmentClient.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _autoAssignAll() async {
    if (_batchAssigning) return;
    setState(() => _batchAssigning = true);
    try {
      final result = await _riderClient.autoAssignAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auto-assigned ${result.assigned} of ${result.attempted} orders',
          ),
          backgroundColor: result.assigned > 0 ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(RiderAssignmentClient.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _batchAssigning = false);
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
              tooltip: 'Refresh rider availability',
              onPressed: _refreshRiders,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 24),
          if (svc.isLoading && svc.orders == null)
            const OrdersAnalyticsSkeleton()
          else ...[
            LiveOrdersStatsRow(stats: statsWithRiders),
            const SizedBox(height: 24),
            PendingDispatchQueue(
              orders: svc.unassignedOrders,
              onView: _openOrder,
              onAssignRider: _assignRider,
              onAutoAssignRider: _autoAssignRider,
              onAutoAssignAll: svc.unassignedOrders.isEmpty ? null : _autoAssignAll,
            ),
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
