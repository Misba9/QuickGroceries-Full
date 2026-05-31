import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';

enum AdminToastKind {
  newOrder,
  orderAssigned,
  orderDelivered,
  orderCancelled,
  lowStock,
  vendorRequest,
  generic,
}

AdminToastKind toastKindForType(String type) {
  switch (type.toLowerCase()) {
    case 'new_order':
      return AdminToastKind.newOrder;
    case 'driver_assigned':
    case 'delivery_assigned':
      return AdminToastKind.orderAssigned;
    case 'order_delivered':
    case 'delivery_completed':
      return AdminToastKind.orderDelivered;
    case 'order_cancelled':
      return AdminToastKind.orderCancelled;
    case 'low_stock':
    case 'stock_low':
    case 'out_of_stock':
      return AdminToastKind.lowStock;
    case 'vendor_request':
    case 'vendor_registered':
      return AdminToastKind.vendorRequest;
    default:
      return AdminToastKind.generic;
  }
}

Color toastAccent(AdminToastKind kind) {
  switch (kind) {
    case AdminToastKind.newOrder:
      return AppColor.primary;
    case AdminToastKind.orderAssigned:
      return Colors.blue.shade700;
    case AdminToastKind.orderDelivered:
      return Colors.green.shade700;
    case AdminToastKind.orderCancelled:
      return Colors.red.shade700;
    case AdminToastKind.lowStock:
      return Colors.orange.shade800;
    case AdminToastKind.vendorRequest:
      return Colors.purple.shade700;
    case AdminToastKind.generic:
      return Colors.blueGrey.shade700;
  }
}

Color toastBackground(AdminToastKind kind) {
  switch (kind) {
    case AdminToastKind.newOrder:
      return const Color(0xFFFFFBE6);
    case AdminToastKind.orderAssigned:
      return Colors.blue.shade50;
    case AdminToastKind.orderDelivered:
      return Colors.green.shade50;
    case AdminToastKind.orderCancelled:
      return Colors.red.shade50;
    case AdminToastKind.lowStock:
      return Colors.orange.shade50;
    case AdminToastKind.vendorRequest:
      return Colors.purple.shade50;
    case AdminToastKind.generic:
      return Colors.white;
  }
}

IconData toastIcon(AdminToastKind kind) {
  switch (kind) {
    case AdminToastKind.newOrder:
      return Icons.notifications_active_rounded;
    case AdminToastKind.orderAssigned:
      return Icons.delivery_dining_rounded;
    case AdminToastKind.orderDelivered:
      return Icons.check_circle_outline_rounded;
    case AdminToastKind.orderCancelled:
      return Icons.cancel_outlined;
    case AdminToastKind.lowStock:
      return Icons.inventory_2_outlined;
    case AdminToastKind.vendorRequest:
      return Icons.storefront_outlined;
    case AdminToastKind.generic:
      return Icons.info_outline_rounded;
  }
}

class AdminOpsToast extends StatelessWidget {
  const AdminOpsToast({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onViewOrder,
  });

  final OpsNotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback? onViewOrder;

  @override
  Widget build(BuildContext context) {
    final kind = toastKindForType(notification.type);
    final accent = toastAccent(kind);
    final bg = toastBackground(kind);
    final meta = notification.metadata;
    final orderId = notification.orderId ?? '';
    final shortId =
        orderId.length > 6 ? orderId.substring(orderId.length - 6) : orderId;
    final customer = meta['customerName']?.toString() ?? '';
    final amount = meta['amount'];
    final vendor = meta['vendorName']?.toString() ?? '';
    final top = MediaQuery.paddingOf(context).top + 12;

    return Positioned(
      top: top,
      right: 16,
      left: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        color: bg,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(toastIcon(kind), color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind == AdminToastKind.newOrder
                          ? 'New Order Received'
                          : notification.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (kind == AdminToastKind.newOrder &&
                        orderId.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Order #$shortId',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (customer.isNotEmpty)
                        Text('Customer: $customer', style: _lineStyle()),
                      if (amount != null)
                        Text(
                          'Amount: ₹${(amount is num ? amount : num.tryParse('$amount') ?? 0).toStringAsFixed(0)}',
                          style: _lineStyle(),
                        ),
                      if (vendor.isNotEmpty)
                        Text('Vendor: $vendor', style: _lineStyle()),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: _lineStyle(),
                      ),
                    ],
                    if (onViewOrder != null && orderId.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onViewOrder,
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View Order',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _lineStyle() => GoogleFonts.poppins(
        fontSize: 12.5,
        color: Colors.grey.shade800,
        height: 1.35,
      );
}
