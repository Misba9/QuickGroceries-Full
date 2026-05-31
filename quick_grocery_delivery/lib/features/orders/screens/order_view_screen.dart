import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/orders/screens/order_status_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
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
    final double totalAmount =
        products.fold(0.0, (sum, item) => sum + (item.price * item.itemCount)) +
        selectedOrder.deliveryCharge;

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
                const Text('Customer Details'),
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
                        "Customer Name: ${selectedOrder.customerName}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("Address: ${selectedOrder.address}"),
                      const SizedBox(height: 5),
                      Text("Phone: ${selectedOrder.phone}"),
                      if (selectedOrder.latitude != null &&
                          selectedOrder.longitude != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Location: ${selectedOrder.latitude}, ${selectedOrder.longitude}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () async {
                    if (selectedOrder.latitude != null &&
                        selectedOrder.longitude != null) {
                      // Use coordinates
                      final String googleMapsUrl =
                          'https://www.google.com/maps/dir/?api=1&destination=${selectedOrder.latitude},${selectedOrder.longitude}';
                      final Uri mapsUri = Uri.parse(googleMapsUrl);
                      if (await canLaunchUrl(mapsUri)) {
                        await launchUrl(
                          mapsUri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open Google Maps'),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location coordinates not available'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue.shade100,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.map, color: Colors.blue),
                        AppSpacing.w10,
                        Text(
                          'Open Map',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                                      Text(
                                        "Price: ₹${product.price * product.itemCount}",
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
                          Text(
                            "Total Items: $totalQty",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Total Amount: ₹$totalAmount",
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
                          '${provider.orderStatus}',
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
                    onTap: () {
                      provider.getCashByCustomer(
                        context,
                        "${products.fold(0.0, (sum, item) => sum + ((double.tryParse(item.price.toString()) ?? 0.0).round() * item.itemCount)).round()}",
                        selectedOrder.id,
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
                            'Get the cash and Complete Order',
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
