import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_details_drawer.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_empty_state.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_filter_bar.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_loading_skeleton.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_manage_header.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_page_shell.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_paginated_table.dart';
import 'package:quick_grocery_admin/view/orders/widgets/refund_stats_row.dart';

class RefundRequestsScreen extends StatefulWidget {
  const RefundRequestsScreen({super.key});

  @override
  State<RefundRequestsScreen> createState() => _RefundRequestsScreenState();
}

class _RefundRequestsScreenState extends State<RefundRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final svc = context.read<OrderService>();
    svc.setModulePage(OrderModulePage.refund);
    if (svc.orders == null) {
      await svc.getOrders();
    }
  }

  void _openOrder(OrderModel order) {
    showOrderDetailsDrawer(context, order);
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<OrderService>();
    final loading = svc.isLoading && svc.orders == null;
    final list = svc.filteredOrders;

    return OrdersPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          OrdersManageHeader(
            page: OrderModulePage.refund,
            trailing: IconButton.filledTonal(
              tooltip: 'Refresh',
              onPressed: () => svc.getOrders(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 24),
          if (loading)
            const OrdersLoadingSkeleton()
          else ...[
            RefundStatsRow(stats: svc.refundStats),
            const SizedBox(height: 24),
            OrdersFiltersBar(svc: svc, showStatusFilters: false),
            const SizedBox(height: 20),
            Text(
              '${list.length} refund / cancelled orders',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              OrdersEmptyState(
                title: 'No refund requests',
                message:
                    'Cancelled orders will appear here for refund and dispute review.',
                onRefresh: () => svc.getOrders(),
              )
            else
              OrdersPaginatedTable(
                orders: list,
                onView: _openOrder,
                minTableWidth: 1100,
              ),
          ],
        ],
      ),
    );
  }
}
