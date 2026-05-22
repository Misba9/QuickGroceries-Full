import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_eta_utils.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_row_actions.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_status_badge.dart';

/// Urgent dispatch queue — unassigned / delayed orders with quick actions.
class PendingDispatchQueue extends StatelessWidget {
  const PendingDispatchQueue({
    super.key,
    required this.orders,
    required this.onView,
  });

  final List<OrderModel> orders;
  final OrderDrawerCallback onView;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Dispatch queue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${orders.length} waiting',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No orders waiting for assignment',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: orders.length.clamp(0, 12),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  return _DispatchCard(
                    order: orders[i],
                    onView: onView,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  const _DispatchCard({
    required this.order,
    required this.onView,
  });

  final OrderModel order;
  final OrderDrawerCallback onView;

  @override
  Widget build(BuildContext context) {
    final delayed = OrderEtaUtils.isDelayed(order);
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: delayed ? const Color(0xFFFFF1F2) : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: delayed ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
          width: delayed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (delayed)
                const Icon(Icons.warning_amber, color: Color(0xFFDC2626), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₹${order.getTotalAmount().toStringAsFixed(0)} · ${OrderEtaUtils.minutesSince(order)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          OrderStatusBadge(order: order, compact: true),
          const Spacer(),
          Row(
            children: [
              Text(
                'ETA ${OrderEtaUtils.etaLabel(order)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              OrderRowActions(order: order, onView: onView),
            ],
          ),
        ],
      ),
    );
  }
}
