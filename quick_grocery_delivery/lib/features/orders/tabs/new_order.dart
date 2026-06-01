import 'package:quick_grocery_delivery/features/home/pages/home_page.dart';
import 'package:quick_grocery_delivery/features/orders/screens/pickup_process_screen.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:provider/provider.dart';

class NewOrderTab extends StatelessWidget {
  const NewOrderTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderService>(
      builder: (context, p, _) {
        if (p.newOrders.isEmpty) {
          return const Center(child: Text('No New Orders Found!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: p.newOrders.length,
          itemBuilder: (context, i) {
            final cart = p.newOrders[i];
            return OrderPendingCard(
              products: cart.products,
              isFastDelivery: cart.deliveryType == 'fast',
              status: cart.orderStatus,
              onAccept: () async {
                final accepted = await p.acceptDelivery(cart.id, order: cart);
                if (!context.mounted || accepted == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickupProcessScreen(order: accepted),
                  ),
                );
              },
              onReject: () async {
                await p.rejectOrder(cart.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delivery rejected')),
                  );
                }
              },
              date: cart.createdDate.length >= 10
                  ? cart.createdDate.substring(0, 10)
                  : cart.createdDate,
              orderId: cart.id.length > 6
                  ? cart.id.substring(0, 6)
                  : cart.id,
              customerName: cart.customerName,
              customerAddress: cart.address,
            );
          },
        );
      },
    );
  }
}
