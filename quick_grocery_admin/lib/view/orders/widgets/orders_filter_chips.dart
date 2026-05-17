import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';

class OrdersFilterChips extends StatelessWidget {
  const OrdersFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final OrderQuickFilter selected;
  final ValueChanged<OrderQuickFilter> onSelected;

  static const _filters = [
    OrderQuickFilter.today,
    OrderQuickFilter.thisWeek,
    OrderQuickFilter.allOrders,
    OrderQuickFilter.cod,
    OrderQuickFilter.paid,
    OrderQuickFilter.highValue,
    OrderQuickFilter.delivered,
    OrderQuickFilter.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final active = selected == f ||
              (f == OrderQuickFilter.allOrders &&
                  (selected == OrderQuickFilter.none));
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.label),
              selected: active,
              showCheckmark: false,
              onSelected: (_) {
                if (f == OrderQuickFilter.allOrders) {
                  onSelected(OrderQuickFilter.allOrders);
                  return;
                }
                onSelected(active ? OrderQuickFilter.allOrders : f);
              },
              selectedColor: AppColor.primary.withValues(alpha: 0.25),
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
