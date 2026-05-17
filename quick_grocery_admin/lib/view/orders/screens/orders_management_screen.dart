import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/services/orders_export_service.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_details_drawer.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_analytics_row.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_charts_section.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_empty_state.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_filter_chips.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_loading_skeleton.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_search_bar.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_table_section.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';

/// Premium orders hub — analytics, filters, table/cards, drawer details.
class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({
    super.key,
    this.preset = OrderListPreset.all,
  });

  final OrderListPreset preset;

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<OrderService>();
      svc.setListPreset(widget.preset);
      if (svc.orders == null) svc.getOrders();
    });
  }

  @override
  void didUpdateWidget(covariant OrdersManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset) {
      context.read<OrderService>().setListPreset(widget.preset);
    }
  }

  void _openOrder(OrderModel order) {
    showOrderDetailsDrawer(context, order);
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<OrderService>();
    final pad = adminResponsivePadding(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: RefreshIndicator(
              color: AppColor.primary,
              onRefresh: () => svc.getOrders(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.preset.subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.preset.subtitle!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (svc.isLoading && svc.orders == null)
                      const OrdersAnalyticsSkeleton()
                    else
                      OrdersAnalyticsRow(analytics: svc.analytics),
                    const SizedBox(height: 16),
                    if (!svc.isLoading || svc.orders != null)
                      OrdersChartsSection(
                        ordersTrend: svc.ordersTrendLast7Days(),
                        revenueTrend: svc.revenueTrendLast7Days(),
                        peakHours: svc.peakHoursToday(),
                      ),
                    const SizedBox(height: 16),
                    _Toolbar(svc: svc),
                    const SizedBox(height: 12),
                    OrdersFilterChips(
                      selected: svc.quickFilter,
                      onSelected: svc.setQuickFilter,
                    ),
                    const SizedBox(height: 16),
              _OrdersListCard(
                svc: svc,
                onView: _openOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatefulWidget {
  const _Toolbar({required this.svc});
  final OrderService svc;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  @override
  void initState() {
    super.initState();
    widget.svc.searchController.addListener(_onText);
  }

  @override
  void dispose() {
    widget.svc.searchController.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 640;
        final search = OrdersSearchBar(
          controller: svc.searchController,
          onChanged: svc.setSearch,
          onClear: svc.clearSearch,
        );
        final actions = _ExportActions(svc: svc);
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 10), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _ExportActions extends StatelessWidget {
  const _ExportActions({required this.svc});
  final OrderService svc;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ToolBtn(
          icon: Icons.download_outlined,
          label: 'CSV',
          onPressed: () => OrdersExportService.exportCsv(
            context,
            svc.filteredOrders,
          ),
        ),
        _ToolBtn(
          icon: Icons.table_chart_outlined,
          label: 'Excel',
          onPressed: () => OrdersExportService.exportExcel(
            context,
            svc.filteredOrders,
          ),
        ),
        _ToolBtn(
          icon: Icons.print_outlined,
          label: 'Print',
          onPressed: () {
            final list = svc.filteredOrders;
            if (list.isEmpty) return;
            OrdersExportService.printOrder(context, list.first);
          },
        ),
        IconButton.filledTonal(
          tooltip: 'Refresh',
          onPressed: () => svc.getOrders(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _OrdersListCard extends StatelessWidget {
  const _OrdersListCard({
    required this.svc,
    required this.onView,
  });

  final OrderService svc;
  final void Function(OrderModel) onView;

  @override
  Widget build(BuildContext context) {
    return WrapperWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${svc.filteredOrders.length} orders',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (svc.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (svc.isLoading && svc.orders == null)
            const OrdersLoadingSkeleton()
          else if (svc.filteredOrders.isEmpty)
            OrdersEmptyState(onRefresh: () => svc.getOrders())
          else ...[
            OrdersTableSection(
              orders: svc.pagedOrders,
              onView: onView,
            ),
            const SizedBox(height: 16),
            _PaginationBar(svc: svc),
          ],
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.svc});
  final OrderService svc;

  @override
  Widget build(BuildContext context) {
    final showing = svc.pagedOrders.length;
    final total = svc.filteredOrders.length;

    return Row(
      children: [
        Text(
          'Showing $showing of $total',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const Spacer(),
        if (svc.hasMore)
          FilledButton.tonal(
            onPressed: svc.loadMore,
            child: const Text('Load more'),
          ),
      ],
    );
  }
}
