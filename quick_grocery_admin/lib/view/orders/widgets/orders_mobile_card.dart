import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_row_actions.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_status_badge.dart';
import 'package:quick_grocery_admin/core/widgets/admin_text_selection.dart';

class OrdersMobileCard extends StatelessWidget {
  const OrdersMobileCard({
    super.key,
    required this.order,
    required this.index,
    required this.onView,
  });

  final OrderModel order;
  final int index;
  final OrderDrawerCallback onView;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(order.createdDate);
    final dateStr = date != null
        ? DateFormat('MMM d, HH:mm').format(date)
        : order.createdDate;

    return Material(
      color: index.isEven ? Colors.white : const Color(0xFFFAFAFB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onView(order),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AdminSelectableText(
                      '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  OrderStatusBadge(order: order, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              AdminSelectableText(
                order.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (order.phone.isNotEmpty)
                AdminSelectableText(
                  order.phone,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (order.deliverySlot != null) ...[
                const SizedBox(height: 6),
                Text(
                  order.deliverySlotLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _pill(
                    order.isPaid ? 'Paid' : 'COD',
                    order.isPaid ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                  if (order.hasCoupon) ...[
                    const SizedBox(width: 8),
                    _pill('Coupon', Colors.deepPurple.shade700),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    '₹${order.getTotalAmount().toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  OrderRowActions(
                    order: order,
                    onView: onView,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
