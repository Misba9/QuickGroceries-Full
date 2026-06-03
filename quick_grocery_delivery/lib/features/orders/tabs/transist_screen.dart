import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/orders/screens/delivery_details_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/tracking/screens/tracking_screen.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

class TransistScreen extends StatelessWidget {
  const TransistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Consumer<OrderService>(
      builder: (context, p, _) {
        return p.orders == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => p.getOrders(),
                child: ListView.builder(
                  itemCount: p.myTransistOrders.length,
                  itemBuilder: (context, i) {
                    return TransistCard(
                      width: MediaQuery.of(context).size.width,
                      orderId: p.myTransistOrders[i].id,
                      address: p.myTransistOrders[i].address,
                      idPaid: p.myTransistOrders[i].isPaid,
                      onTap: () {
                        final order = p.myTransistOrders[i];
                        p.onSelectOrder(order);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DeliveryDetailsScreen(order: order),
                          ),
                        );
                      },
                      products:
                          p.myTransistOrders[i].products, // List<ProductItem>
                    );
                  },
                ),
              );
      },
    );
  }
}

class TransistCard extends StatelessWidget {
  const TransistCard({
    super.key,
    required this.width,
    required this.orderId,
    required this.address,
    required this.idPaid,
    required this.onTap,
    required this.products,
  });

  final double width;
  final String orderId;
  final String address;
  final bool idPaid;
  final Function() onTap;
  final List<ProductItem> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Paid Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ${orderId.substring(0, 8)}',
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: idPaid ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  idPaid ? 'Paid' : 'Not Paid',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // List of Products (up to 3)
          Column(
            children: products.take(3).map((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        product.image,
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    AppSpacing.w10,
                    Expanded(
                      child: Text(
                        '${product.name} x${product.itemCount}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GlobalVariables.darkGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 5),

          // Address + View Button
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GlobalVariables.darkGrey,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 36,
                  width: width * 0.22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: const Center(child: Text('View')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
