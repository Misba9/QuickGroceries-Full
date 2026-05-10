import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/app_style.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    Provider.of<OrderService>(context, listen: false).getDeliveryBoy();
    Provider.of<OrderService>(context, listen: false).getTotalOrders();
    Provider.of<OrderService>(context, listen: false).getOrders();
    Provider.of<OrderService>(context, listen: false).updateAdminFcmToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quick Groceries Delivery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: GlobalVariables.primary,
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundImage: provider.deliveryBoy == null
                ? null
                : provider.deliveryBoy!.image == ''
                ? null
                : NetworkImage(provider.deliveryBoy!.image),
          ),
          AppSpacing.w10,
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RefreshIndicator(
            onRefresh: () => provider.getOrders(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlobalVariables.verticalSpace,
                  ScanPay(width: width),
                  GlobalVariables.verticalSpace,
                  FutureBuilder<Map<String, dynamic>>(
                    future: provider.fetchTotalOrdersAndPrice(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return const Center(child: Text('No data available'));
                      }
                      final data = snapshot.data!;
                      return Row(
                        children: [
                          LeadingCard(
                            width: width,
                            title: 'Total Amount',
                            value: "₹${data['totalOrderPrice'].toString()}",
                          ),
                          const SizedBox(width: 20),
                          LeadingCard(
                            width: width,
                            title: 'Total Orders',
                            value: data['totalOrders'].toString(),
                          ),
                        ],
                      );
                    },
                  ),
                  GlobalVariables.verticalSpace,
                  const Text(
                    'Pending Orders',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  GlobalVariables.verticalSpace,
                  Consumer<OrderService>(
                    builder: (context, p, _) {
                      if (p.newOrders.isEmpty) {
                        return const Center(
                          child: Text('No New Orders Found!'),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => p.getOrders(),
                        child: ListView.builder(
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
                        ),
                      );
                    },
                  ),
                  // CategoryTile(
                  //   onTap: () {},
                  //   title: 'Pickup',
                  // ),
                  // ListView.builder(
                  //     physics: const NeverScrollableScrollPhysics(),
                  //     itemCount: 2,
                  //     shrinkWrap: true,
                  //     itemBuilder: (context, i) {
                  //       return OrderCard(width: width);
                  //     }),
                  // CategoryTile(
                  //   onTap: () {},
                  //   title: 'Delivery',
                  // ),
                  // ListView.builder(
                  //   physics: const NeverScrollableScrollPhysics(),
                  //   itemCount: 3,
                  //   shrinkWrap: true,
                  //   itemBuilder: (context, i) {
                  //     return OrderCard(width: width);
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrderPendingCard extends StatelessWidget {
  const OrderPendingCard({
    super.key,
    required this.products,
    required this.date,
    required this.orderId,
    required this.customerName,
    required this.customerAddress,
    required this.onTap,
    required this.status,
    required this.isFastDelivery,
  });

  final List<ProductItem> products;
  final String date;
  final String orderId;
  final String customerName;
  final String customerAddress;
  final Function() onTap;
  final String status;
  final bool isFastDelivery;

  @override
  Widget build(BuildContext context) {
    double totalAmount = products.fold(
      0,
      (sum, item) => sum + ((item.price ?? 0) * (item.itemCount ?? 0)),
    );

    int totalQty = products.fold(0, (sum, item) => sum + (item.itemCount ?? 0));

    final firstProduct = products.first;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: GestureDetector(
            onTap: onTap,
            child: Card(
              margin: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Product + Customer Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(firstProduct.image),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        AppSpacing.w10,
                        // Product + Customer Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(
                                products.length == 1
                                    ? firstProduct.name
                                    : '${firstProduct.name} + ${products.length - 1} more',
                                style: AppStyle.titleBold,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppSpacing.h5,
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(
                                '$customerName | $customerAddress',
                                style: AppStyle.subSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppSpacing.h5,
                            Row(
                              children: [
                                Text(
                                  'Ordered on: $date',
                                  style: AppStyle.subSmall,
                                ),
                                AppSpacing.w20,
                                Text(
                                  'Order ID: $orderId',
                                  style: AppStyle.subSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.h10,
                    // Summary Box
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 80,
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Amount
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Amount', style: AppStyle.subSmall),
                              AppSpacing.h5,
                              Text(
                                '₹${totalAmount.toStringAsFixed(2)}',
                                style: AppStyle.titleBold,
                              ),
                            ],
                          ),
                          // Qty
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Total Qty', style: AppStyle.subSmall),
                              AppSpacing.h5,
                              Text(
                                totalQty.toString(),
                                style: AppStyle.titleBold,
                              ),
                            ],
                          ),
                          // Order Status
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Order Status',
                                style: AppStyle.subSmall,
                              ),
                              AppSpacing.h5,
                              Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Fast Delivery Label
        if (isFastDelivery)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              height: 30,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green,
              ),
              child: const Center(
                child: Text(
                  'Fast Delivery',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
