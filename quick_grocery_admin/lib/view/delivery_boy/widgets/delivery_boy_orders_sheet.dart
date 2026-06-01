import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/model/delivery_boy_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/delivery_boy/domain/delivery_boy_order_stats.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';

/// Shows orders handled by a delivery partner (from live Firestore index).
class DeliveryBoyOrdersSheet {
  DeliveryBoyOrdersSheet._();

  static Future<void> show(
    BuildContext context, {
    required DeliveryPersonModel rider,
    required DeliveryBoyOrderStats stats,
    required List<Map<String, dynamic>> orders,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final name = '${rider.firstName} ${rider.lastName}'.trim();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    name.isEmpty ? 'Delivery orders' : name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total ${stats.total} · Assigned ${stats.assigned} · '
                    'Active ${stats.active} · Completed ${stats.completed}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: orders.isEmpty
                        ? const Center(child: Text('No orders for this rider yet.'))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: orders.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final d = orders[i];
                              final id = (d['id'] ?? '').toString();
                              final customer =
                                  (d['customer_name'] ?? d['customerName'] ?? '—')
                                      .toString();
                              final amount = OpsFirestoreHelpers.orderTotal(d);
                              final status =
                                  (d['order_status'] ?? d['status'] ?? '—')
                                      .toString();
                              final delivered = OpsFirestoreHelpers.isDelivered(d);
                              final date = _formatDate(
                                delivered
                                    ? OpsFirestoreHelpers.parseDate(
                                        d['deliveredTime'] ??
                                            d['delivered_time'],
                                      )
                                    : OpsFirestoreHelpers.createdAt(d),
                              );
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '#${OpsFirestoreHelpers.shortOrderId(id)} · $customer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '$status · $date',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  '₹${amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
  }
}

/// Tappable total-orders badge for the delivery boy table.
class DeliveryBoyTotalOrdersCell extends StatelessWidget {
  const DeliveryBoyTotalOrdersCell({
    super.key,
    required this.stats,
    required this.onTap,
  });

  final DeliveryBoyOrderStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: stats.total > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: stats.total > 0
              ? AppColor.primary.withValues(alpha: 0.15)
              : Colors.grey.shade200,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${stats.total}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: stats.total > 0 ? Colors.black87 : Colors.grey,
              ),
            ),
            if (stats.total > 0) ...[
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 14, color: Colors.grey.shade700),
            ],
          ],
        ),
      ),
    );
  }
}
