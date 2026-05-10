import 'package:quick_grocery_delivery/features/home/pages/home_page.dart';
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
        return RefreshIndicator(
          onRefresh: () => p.getOrders(),
          child: ListView.builder(
            itemCount: p.newOrders.length,
            itemBuilder: (context, i) {
              return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: p.newOrders.length,
                itemBuilder: (context, i) {
                  final cart = p.newOrders[i];

                  return OrderPendingCard(
                    products: cart.products,
                    isFastDelivery: cart.deliveryType == 'fast',
                    status: cart.orderStatus,
                    onTap: () {
                      p.showConfirmationDialog(
                        context,
                        p.newOrders[i].id,
                        p.newOrders[i].uuid,
                      );
                    },
                    date: cart.createdDate.substring(0, 10),
                    orderId: cart.id.substring(0, 6),
                    customerName: cart.customerName,
                    customerAddress: cart.address,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
