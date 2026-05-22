import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/services/orders_export_service.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_filter_chips.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_search_bar.dart';

/// Search, filters, and export for manage/refund pages.
class OrdersFiltersBar extends StatefulWidget {
  const OrdersFiltersBar({
    super.key,
    required this.svc,
    this.showStatusFilters = true,
  });

  final OrderService svc;
  final bool showStatusFilters;

  @override
  State<OrdersFiltersBar> createState() => _OrdersFiltersBarState();
}

class _OrdersFiltersBarState extends State<OrdersFiltersBar> {
  @override
  void initState() {
    super.initState();
    widget.svc.searchController.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.svc.searchController.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 720;
              final search = OrdersSearchBar(
                controller: svc.searchController,
                onChanged: svc.setSearch,
                onClear: svc.clearSearch,
              );
              final actions = _ExportRow(svc: svc);
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 10), actions],
                );
              }
              final searchWidth = c.maxWidth.isFinite
                  ? math.max(200.0, c.maxWidth - 280)
                  : 320.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: searchWidth, child: search),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
          if (widget.showStatusFilters) ...[
            const SizedBox(height: 12),
            OrdersFilterChips(
              selected: svc.quickFilter,
              onSelected: svc.setQuickFilter,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExportRow extends StatelessWidget {
  const _ExportRow({required this.svc});
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
          onPressed: () =>
              OrdersExportService.exportCsv(context, svc.filteredOrders),
        ),
        _ToolBtn(
          icon: Icons.table_chart_outlined,
          label: 'Excel',
          onPressed: () =>
              OrdersExportService.exportExcel(context, svc.filteredOrders),
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
