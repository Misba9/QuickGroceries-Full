import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  DateTime? selectedDate;

  void _selectDate() async {
    DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDate: selectedDate ?? now,
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  String get formattedDate {
    if (selectedDate == null) return 'Select Date';
    return DateFormat('dd MMM yyyy').format(selectedDate!);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Center(
                  child: Text(
                    'Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                GlobalVariables.verticalSpace,
                GlobalVariables.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          height: height * .07,
                          width: width,
                          decoration: BoxDecoration(
                            border: Border.all(width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.expand_more_rounded, size: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // show QR code dialog
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          height: height * .07,
                          width: width,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Scan & Pay'),
                              SizedBox(
                                height: 30,
                                width: 30,
                                child: Image.asset(AppIcons.scan),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                GlobalVariables.verticalSpace,
                Consumer<OrderService>(
                  builder: (context, p, _) {
                    final filteredOrders = selectedDate == null
                        ? p.totalOrders
                        : p.totalOrders.where((order) {
                            final orderDate = DateTime.parse(order.createdDate);
                            return orderDate.year == selectedDate!.year &&
                                orderDate.month == selectedDate!.month &&
                                orderDate.day == selectedDate!.day;
                          }).toList();

                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredOrders.length,
                      shrinkWrap: true,
                      itemBuilder: (context, i) {
                        final order = filteredOrders[i];
                        double n(dynamic v) {
                          if (v is num) return v.toDouble();
                          return double.tryParse('$v') ?? 0;
                        }

                        final bill = order.bill ?? const <String, dynamic>{};
                        final totalAmount = n(
                          bill['grandTotal'] ?? bill['total'],
                        );
                        final totalItems = order.products.fold<int>(
                          0,
                          (sum, item) => sum + item.itemCount,
                        );

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Meta
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.id.substring(0, 8)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.h5,
                              Text(
                                '${order.customerName} • ${order.phone}',
                                style: const TextStyle(
                                  color: GlobalVariables.darkGrey,
                                  fontSize: 15,
                                ),
                              ),
                              AppSpacing.h5,
                              Text(
                                DateFormat(
                                  "dd . MMM . yy | h:mm a",
                                ).format(DateTime.parse(order.createdDate)),
                                style: const TextStyle(
                                  color: GlobalVariables.darkGrey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Products List (max 3 shown)
                              Column(
                                children: order.products.take(3).map((product) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            product.image,
                                            height: 30,
                                            width: 30,
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
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₹${product.lineTotal.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),

                              // Total Items
                              AppSpacing.h10,
                              Text(
                                'Total Items: $totalItems',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
