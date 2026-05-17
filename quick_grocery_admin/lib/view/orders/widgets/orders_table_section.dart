import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_row_actions.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_status_badge.dart';
import 'package:quick_grocery_admin/view/orders/widgets/orders_mobile_card.dart';

class OrdersTableSection extends StatelessWidget {
  const OrdersTableSection({
    super.key,
    required this.orders,
    required this.onView,
  });

  final List<OrderModel> orders;
  final OrderDrawerCallback onView;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (adminIsMobileWidth(c.maxWidth)) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => OrdersMobileCard(
              order: orders[i],
              index: i,
              onView: onView,
            ),
          );
        }
        return _DesktopOrdersTable(orders: orders, onView: onView);
      },
    );
  }
}

class _DesktopOrdersTable extends StatelessWidget {
  const _DesktopOrdersTable({
    required this.orders,
    required this.onView,
  });

  final List<OrderModel> orders;
  final OrderDrawerCallback onView;

  static const _headers = [
    'SL',
    'Order ID',
    'Customer',
    'Date',
    'Payment',
    'Total',
    'Status',
    'Actions',
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF8F9FB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: _headers
                    .map(
                      (h) => Expanded(
                        flex: h == 'Actions' ? 2 : 1,
                        child: Text(
                          h,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final o = orders[index];
                final date = DateTime.tryParse(o.createdDate);
                final zebra = index.isEven;
                return Material(
                  color: zebra ? Colors.white : const Color(0xFFFAFAFB),
                  child: InkWell(
                    onTap: () => onView(o),
                    hoverColor: AppColor.primary.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              o.id.length > 10
                                  ? '${o.id.substring(0, 10)}…'
                                  : o.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  o.phone,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              date != null
                                  ? DateFormat('MMM d, HH:mm').format(date)
                                  : '—',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(child: _paymentChip(o)),
                          Expanded(
                            child: Text(
                              '₹${o.getTotalAmount().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: OrderStatusBadge(order: o, compact: true),
                          ),
                          Expanded(
                            flex: 2,
                            child: OrderRowActions(
                              order: o,
                              onView: onView,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentChip(OrderModel o) {
    final paid = o.isPaid;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: paid
              ? Colors.green.shade50
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          paid ? 'Paid' : 'COD',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: paid ? Colors.green.shade800 : Colors.orange.shade900,
          ),
        ),
      ),
    );
  }
}
