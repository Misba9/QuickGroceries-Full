import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/app_style.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/payment/screens/scan_pay_screen.dart';
import 'package:quick_grocery_delivery/widgets/driver_stat_card.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/features/orders/screens/pickup_process_screen.dart';
import 'package:quick_grocery_delivery/services/driver_location_publisher.dart';
import 'package:quick_grocery_delivery/support/support_contact_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DriverLocationPublisher _locationPublisher = DriverLocationPublisher();

  @override
  void initState() {
    super.initState();
    final orders = Provider.of<OrderService>(context, listen: false);
    orders.getDeliveryBoy();
    orders.getTotalOrders();
    orders.startRealtimeOrders();
    orders.updateAdminFcmToken();
    _locationPublisher.start();
  }

  @override
  void dispose() {
    _locationPublisher.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);
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
          IconButton(
            icon: const Icon(Icons.support_agent_outlined),
            tooltip: 'Support',
            onPressed: () => SupportContactSheet.show(context),
          ),
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
          child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlobalVariables.verticalSpace,
                  _ScanPayBanner(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanPayScreen()),
                    ),
                  ),
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
                          Expanded(
                            child: DriverStatCard(
                              label: 'Total Amount',
                              value: '₹${data['totalOrderPrice']}',
                              icon: Icons.currency_rupee,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DriverStatCard(
                              label: 'Total Orders',
                              value: '${data['totalOrders']}',
                              icon: Icons.receipt_long_outlined,
                            ),
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
                              onAccept: () async {
                                final accepted =
                                    await p.acceptDelivery(cart.id, order: cart);
                                if (!context.mounted || accepted == null) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PickupProcessScreen(order: accepted),
                                  ),
                                );
                              },
                              onReject: () async {
                                await p.rejectOrder(cart.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Delivery rejected'),
                                    ),
                                  );
                                }
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
    );
  }
}

class _ScanPayBanner extends StatelessWidget {
  const _ScanPayBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GlobalVariables.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan & Pay',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text('Verify customer payments instantly'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
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
    required this.status,
    required this.isFastDelivery,
    this.onAccept,
    this.onReject,
    this.onTap,
  });

  final List<ProductItem> products;
  final String date;
  final String orderId;
  final String customerName;
  final String customerAddress;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
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
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(10),
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
                  if (onAccept != null || onReject != null) ...[
                    AppSpacing.h10,
                    Row(
                      children: [
                        if (onReject != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Reject Delivery'),
                            ),
                          ),
                        if (onAccept != null && onReject != null)
                          AppSpacing.w10,
                        if (onAccept != null)
                          Expanded(
                            child: FilledButton(
                              onPressed: onAccept,
                              style: FilledButton.styleFrom(
                                backgroundColor: GlobalVariables.primary,
                              ),
                              child: const Text('Accept Delivery'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
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
