import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';
import 'package:quick_grocery_admin/view/orders/services/invoice_service.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_contact_actions.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_status_badge.dart';

/// Opens order details as end drawer (desktop) or full-width sheet (mobile).
Future<void> showOrderDetailsDrawer(
  BuildContext context,
  OrderModel order,
) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Align(
      alignment: wide ? Alignment.centerRight : Alignment.bottomCenter,
      child: Material(
        borderRadius: wide
            ? const BorderRadius.horizontal(left: Radius.circular(24))
            : const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: wide ? 480 : MediaQuery.sizeOf(ctx).width,
          height: wide
              ? MediaQuery.sizeOf(ctx).height
              : MediaQuery.sizeOf(ctx).height * 0.92,
          child: OrderDetailsDrawerBody(order: order),
        ),
      ),
    ),
  );
}

class OrderDetailsDrawerBody extends StatefulWidget {
  const OrderDetailsDrawerBody({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderDetailsDrawerBody> createState() => _OrderDetailsDrawerBodyState();
}

class _OrderDetailsDrawerBodyState extends State<OrderDetailsDrawerBody> {
  @override
  void initState() {
    super.initState();
    final svc = context.read<OrderService>();
    svc.getCustomer(widget.order.uuid);
    if (widget.order.products.isNotEmpty) {
      svc.getVendor(widget.order.products.first.vendorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<OrderService>();
    final o = widget.order;
    final date = DateTime.tryParse(o.createdDate);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${o.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (date != null)
                      Text(
                        DateFormat('EEE, MMM d · HH:mm').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              OrderStatusBadge(order: o),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(
                'Customer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(o.phone),
                    if (svc.customer != null)
                      Text(
                        svc.customer!.email,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              _section(
                'Delivery address',
                child: Text(o.address),
              ),
              _section(
                'Payment',
                child: Row(
                  children: [
                    _kv('Method', o.isPaid ? 'Online (Paid)' : 'COD'),
                    const SizedBox(width: 24),
                    _kv('Total', '₹${o.getTotalAmount().toStringAsFixed(2)}'),
                  ],
                ),
              ),
              _section(
                'Items (${o.products.length})',
                child: Column(
                  children: o.products.map((p) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          p.image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      title: Text(p.name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('×${p.itemCount} · ₹${p.price}'),
                      trailing: Text(
                        '₹${(p.price * p.itemCount).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                ),
              ),
              _section(
                'Timeline',
                child: _Timeline(order: o),
              ),
              if (svc.vendor != null)
                _section(
                  'Shop',
                  child: Text(svc.vendor!.shopName),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => InvoiceService.printInvoice(
                      order: o,
                      customer: svc.customer,
                      vendor: svc.vendor,
                      context: context,
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Invoice'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        OrderContactActions.callCustomer(context, o.phone),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => OrderContactActions.whatsAppCustomer(
                      context,
                      o.phone,
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AdminPrimaryButton(
                label: 'Open full details',
                icon: Icons.open_in_new_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(order: o),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColor.primary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[
      _Step('Order placed', order.createdDate, true),
      _Step('Confirmed', order.confimedTime, order.confimedTime.isNotEmpty),
      _Step('At shop', order.driverGoShopTime, order.driverGoShopTime.isNotEmpty),
      _Step('Picked up', order.orderPickedTime, order.orderPickedTime.isNotEmpty),
      _Step('On the way', order.onTheWayTime, order.onTheWayTime.isNotEmpty),
      _Step('Delivered', order.orderDeliveredTime, order.isDelivered),
    ];

    return Column(
      children: steps.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                s.done ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: s.done ? const Color(0xFF059669) : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        fontWeight: s.done ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    if (s.time.isNotEmpty && s.done)
                      Text(
                        s.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Step {
  _Step(this.label, this.time, this.done);
  final String label;
  final String time;
  final bool done;
}
