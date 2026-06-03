import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/widgets/assign_rider_dialog.dart';
import 'package:quick_grocery_admin/view/orders/services/invoice_service.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_contact_actions.dart';
typedef OrderDrawerCallback = void Function(OrderModel order);

/// Grouped order actions — single popup menu per row.
class OrderRowActions extends StatelessWidget {
  const OrderRowActions({super.key, required this.order, required this.onView});

  final OrderModel order;
  final OrderDrawerCallback onView;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Order actions',
      icon: Icon(Icons.more_horiz_rounded, color: AppColor.primary),
      onSelected: (v) => _handle(context, v),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'view', child: Text('View Details')),
        PopupMenuItem(value: 'assign', child: Text('Assign Rider')),
        PopupMenuItem(value: 'track', child: Text('Track Order')),
        PopupMenuItem(value: 'invoice', child: Text('Generate Invoice')),
        PopupMenuItem(value: 'call', child: Text('Call Customer')),
        PopupMenuItem(value: 'wa', child: Text('WhatsApp')),
      ],
    );
  }

  void _handle(BuildContext context, String value) {
    switch (value) {
      case 'view':
        onView(order);
        break;
      case 'invoice':
        InvoiceService.printInvoice(order: order, context: context);
        break;
      case 'assign':
        _assignDelivery(context);
        break;
      case 'call':
        OrderContactActions.callCustomer(context, order.phone);
        break;
      case 'wa':
        OrderContactActions.whatsAppCustomer(
          context,
          order.phone,
          message: 'Hi ${order.customerName}, regarding order #${order.id}',
        );
        break;
      case 'track':
        OrderContactActions.trackOrder(context, order.lat, order.lng);
        break;
    }
  }

  Future<void> _assignDelivery(BuildContext context) async {
    final ok = await AssignRiderDialog.show(context, order: order);
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rider assigned')),
      );
    }
  }
}
