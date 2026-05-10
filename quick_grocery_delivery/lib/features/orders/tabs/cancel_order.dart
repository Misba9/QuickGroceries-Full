import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/orders/screens/order_view_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

class CompletedOrderScreen extends StatelessWidget {
  const CompletedOrderScreen({super.key});

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
                  itemCount: p.myCompletedOrders.length,
                  itemBuilder: (context, i) {
                    return CompletedCard(
                      width: MediaQuery.of(context).size.width,
                      orderId: p.myCompletedOrders[i].id,
                      address: p.myCompletedOrders[i].address,
                      isPaid: p.myCompletedOrders[i].isPaid,
                      onTap: () {
                        p.onSelectOrder(p.myCompletedOrders[i]);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const OrderViewScreen(isCompleted: true),
                          ),
                        );
                      },
                      products:
                          p.myCompletedOrders[i].products, // List<ProductItem>
                    );
                  },
                ),
              );
      },
    );
  }
}

class CompletedCard extends StatelessWidget {
  const CompletedCard({
    super.key,
    required this.width,
    required this.orderId,
    required this.address,
    required this.isPaid,
    required this.onTap,
    required this.products,
  });

  final double width;
  final String orderId;
  final String address;
  final bool isPaid;
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
          // Top row with order ID and paid status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ${orderId.substring(0, 8)}',
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Not Paid',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // List of product thumbnails + names
          Column(
            children: products.take(3).map((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
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
                        style: const TextStyle(
                          color: GlobalVariables.darkGrey,
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Address and View button
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GlobalVariables.darkGrey,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 36,
                  width: width * 0.22,
                  margin: const EdgeInsets.only(left: 10),
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
