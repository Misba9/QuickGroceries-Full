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

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final svc = context.read<OrderService>();
    svc.setModulePage(OrderModulePage.manage);
    svc.setQuickFilter(OrderQuickFilter.allOrders);
    if (svc.orders == null) await svc.getOrders();
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
          const OrdersManageHeader(page: OrderModulePage.manage),
          const SizedBox(height: 24),
          OrdersFiltersBar(svc: svc),
          const SizedBox(height: 20),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                '${list.length} orders',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (svc.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const OrdersLoadingSkeleton()
          else if (list.isEmpty)
            OrdersEmptyState(onRefresh: () => svc.getOrders())
          else
            OrdersPaginatedTable(
              orders: list,
              onView: _openOrder,
            ),
        ],
      ),
    );
  }
}
