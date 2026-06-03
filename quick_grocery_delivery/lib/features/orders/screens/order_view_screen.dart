import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/orders/screens/order_status_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/delivery_order_detail_panel.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/order_earnings_card.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/order_live_builder.dart';
import 'package:quick_grocery_delivery/features/payment/screens/order_collect_payment_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderViewScreen extends StatelessWidget {
  const OrderViewScreen({super.key, required this.isCompleted});
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);
    final selectedOrder = provider.selectedOrder!;
    final products = selectedOrder.products;

    final int totalQty = products.fold(
      0,
      (sum, item) => sum + (item.itemCount),
    );
    final double mrpTotal = products.fold(
      0.0,
      (sum, item) =>
          sum + ((item.unitMrp > item.unitPricePaid ? item.unitMrp : item.unitPricePaid) * item.itemCount),
    );
    final bill = selectedOrder.bill ?? const <String, dynamic>{};
    double n(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }
    final productDiscount = (mrpTotal - n(bill['subtotal'])).clamp(0.0, double.infinity);
    final totalAmount = n(bill['grandTotal'] ?? bill['total']);

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Details'),
                const SizedBox(height: 10),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: ${selectedOrder.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text("Ordered On: ${selectedOrder.createdDate}"),
                      const SizedBox(height: 5),
                      Text("Address: ${selectedOrder.address}"),
                      const SizedBox(height: 5),
                      Text("Phone: ${selectedOrder.phone}"),
                      if (selectedOrder.deliverySlotLabel.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Delivery slot: ${selectedOrder.deliverySlotLabel}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selectedOrder.deliveryInstructionLines.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  const Text('Delivery Instructions'),
                  const SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: selectedOrder.deliveryInstructionLines
                          .map((line) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(line),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                OrderLiveBuilder(
                  orderId: selectedOrder.id,
                  seed: selectedOrder,
                  builder: (context, live) => DeliveryOrderDetailPanel(
                    order: live,
                    showCustomerNotReachable: false,
                  ),
                ),
                const SizedBox(height: 15),
                OrderEarningsCard(order: selectedOrder),
                const SizedBox(height: 15),
                const Text('Product Details'),
                const SizedBox(height: 10),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.image,
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Qty: ${product.itemCount}"),
                                      if (product.hasPurchasedDiscount)
                                        Text(
                                          "₹${product.unitMrp.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        "₹${product.lineTotal.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (product.hasPurchasedDiscount)
                                        Text(
                                          "Saved ₹${((product.unitMrp - product.unitPricePaid) * product.itemCount).toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('MRP Total', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('₹${mrpTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      if (productDiscount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Product Discount', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('-₹${productDiscount.toStringAsFixed(0)}'),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Item Total', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('₹${n(bill['subtotal']).toStringAsFixed(0)}'),
                        ],
                      ),
                      if (n(bill['handlingCharge']) > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Handling Fee'),
                            Text('₹${n(bill['handlingCharge']).toStringAsFixed(0)}'),
                          ],
                        ),
                      if (n(bill['platformFee']) > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Platform Fee'),
                            Text('₹${n(bill['platformFee']).toStringAsFixed(0)}'),
                          ],
                        ),
                      if (n(bill['deliveryPartnerTip'] ?? bill['tipAmount']) > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Partner Tip'),
                            Text('₹${n(bill['deliveryPartnerTip'] ?? bill['tipAmount']).toStringAsFixed(0)}'),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Items: $totalQty",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Grand Total: ₹${totalAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final Uri callUri = Uri(
                      scheme: 'tel',
                      path: "+91${selectedOrder.phone}",
                    );
                    if (await canLaunchUrl(callUri)) {
                      await launchUrl(callUri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.call),
                        AppSpacing.w10,
                        const Text('Contact'),
                      ],
                    ),
                  ),
                ),
                AppSpacing.h20,
                Visibility(
                  visible: !isCompleted,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule),
                        AppSpacing.w10,
                        const Text('Order Status:'),
                        AppSpacing.w10,
                        Text(
                          provider.orderStatus,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.h20,
                Visibility(
                  visible: !isCompleted && !selectedOrder.isPaid,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderCollectPaymentScreen(order: selectedOrder),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.payments_outlined),
                          AppSpacing.w10,
                          Text(
                            'Collect Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: !isCompleted && selectedOrder.isPaid,
                  child: GestureDetector(
                    onTap: () {
                      provider.showOrderConfirmationDialog(
                        context,
                        selectedOrder.id,
                        selectedOrder.uuid,
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.done),
                          AppSpacing.w10,
                          Text(
                            'Click to complete the Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isCompleted
          ? null
          : GestureDetector(
              onTap: () {
                showUpdateStatusDialog(
                  context,
                  selectedOrder.id,
                  selectedOrder.uuid,
                );
              },
              child: Container(
                margin: const EdgeInsets.all(20),
                height: 60,
                decoration: BoxDecoration(
                  color: GlobalVariables.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                width: MediaQuery.of(context).size.width,
                child: const Center(
                  child: Text(
                    'Update Status',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
    );
  }
}
