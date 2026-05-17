import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/orders/services/invoice_service.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_contact_actions.dart';
import 'package:provider/provider.dart';

typedef OrderDrawerCallback = void Function(OrderModel order);

class OrderRowActions extends StatelessWidget {
  const OrderRowActions({
    super.key,
    required this.order,
    required this.onView,
    this.compact = false,
  });

  final OrderModel order;
  final OrderDrawerCallback onView;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return PopupMenuButton<String>(
        tooltip: 'Actions',
        onSelected: (v) => _handle(context, v),
        itemBuilder: (_) => _menuItems(),
        child: Icon(Icons.more_horiz_rounded, color: AppColor.primary),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _ActionBtn(
          icon: Icons.visibility_outlined,
          tooltip: 'View',
          onTap: () => onView(order),
        ),
        _ActionBtn(
          icon: Icons.receipt_long_outlined,
          tooltip: 'Receipt',
          onTap: () => InvoiceService.printInvoice(order: order, context: context),
        ),
        _ActionBtn(
          icon: Icons.delivery_dining_outlined,
          tooltip: 'Assign delivery',
          onTap: () => _assignDelivery(context),
        ),
        _ActionBtn(
          icon: Icons.call_outlined,
          tooltip: 'Call',
          onTap: () => OrderContactActions.callCustomer(context, order.phone),
        ),
        _ActionBtn(
          icon: Icons.chat_outlined,
          tooltip: 'WhatsApp',
          onTap: () => OrderContactActions.whatsAppCustomer(
            context,
            order.phone,
            message: 'Hi ${order.customerName}, regarding order #${order.id}',
          ),
        ),
        _ActionBtn(
          icon: Icons.map_outlined,
          tooltip: 'Track',
          onTap: () =>
              OrderContactActions.trackOrder(context, order.lat, order.lng),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _menuItems() => const [
        PopupMenuItem(value: 'view', child: Text('View details')),
        PopupMenuItem(value: 'invoice', child: Text('Print receipt')),
        PopupMenuItem(value: 'assign', child: Text('Assign delivery')),
        PopupMenuItem(value: 'call', child: Text('Call customer')),
        PopupMenuItem(value: 'wa', child: Text('WhatsApp')),
        PopupMenuItem(value: 'track', child: Text('Track order')),
      ];

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
        OrderContactActions.whatsAppCustomer(context, order.phone);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery partner assigned')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign delivery partner')),
      );
    }
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: AppColor.primary),
    );
  }
}
