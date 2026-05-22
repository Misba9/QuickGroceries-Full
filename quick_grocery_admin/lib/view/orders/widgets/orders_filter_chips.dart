import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';

/// Status/payment filter chips for [ManageOrdersScreen].
class OrdersFilterChips extends StatelessWidget {
  const OrdersFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final OrderQuickFilter selected;
  final ValueChanged<OrderQuickFilter> onSelected;
  final bool compact;

  static const manageFilters = [
    OrderQuickFilter.allOrders,
    OrderQuickFilter.pending,
    OrderQuickFilter.assigned,
    OrderQuickFilter.waiting,
    OrderQuickFilter.delivered,
    OrderQuickFilter.cancelled,
    OrderQuickFilter.cod,
    OrderQuickFilter.online,
    OrderQuickFilter.highValue,
    OrderQuickFilter.scheduled,
  ];

  @override
  Widget build(BuildContext context) {
    final filters = compact
        ? const [
            OrderQuickFilter.allOrders,
            OrderQuickFilter.pending,
            OrderQuickFilter.delivered,
            OrderQuickFilter.cancelled,
          ]
        : manageFilters;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final active = selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.label),
              selected: active,
              showCheckmark: false,
              onSelected: (_) => onSelected(f),
              selectedColor: AppColor.primary.withValues(alpha: 0.22),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active ? AppColor.primary : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFF1A1A1A) : Colors.grey.shade700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
