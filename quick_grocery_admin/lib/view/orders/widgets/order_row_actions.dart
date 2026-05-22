import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/orders/services/invoice_service.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_contact_actions.dart';
import 'package:provider/provider.dart';

typedef OrderDrawerCallback = void Function(OrderModel order);

/// Grouped order actions — single popup menu per row.
class OrderRowActions extends StatelessWidget {
  const OrderRowActions({
    super.key,
    required this.order,
    required this.onView,
  });

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
    final deliverySvc = context.read<DeliveryBoyService>();
    if (deliverySvc.deliveryBoys == null) {
      await deliverySvc.getDeliveryBoys();
    }
    final boys = deliverySvc.deliveryBoys ?? [];
    if (!context.mounted) return;

    if (boys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery partners found')),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign delivery partner'),
        content: SizedBox(
          width: 360,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: boys.length,
            itemBuilder: (_, i) {
              final b = boys[i];
              return ListTile(
                title: Text('${b.firstName} ${b.lastName}'),
                subtitle: Text(b.phone),
                onTap: () => Navigator.pop(ctx, b.id),
              );
            },
          ),
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    try {
      await context.read<OrderService>().assignDeliveryBoy(order.id, selected);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery partner assigned')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign delivery partner')),
      );
    }
  }
}
