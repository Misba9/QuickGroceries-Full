import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DeliveredOrdersScreeen extends StatefulWidget {
  const DeliveredOrdersScreeen({super.key});

  @override
  State<DeliveredOrdersScreeen> createState() => _DeliveredOrdersScreeenState();
}

class _DeliveredOrdersScreeenState extends State<DeliveredOrdersScreeen> {
  @override
  void initState() {
    Provider.of<OrderService>(context, listen: false).getOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            PrimaryAppBar(),
            AppSpacing.h20,
            WrapperWidget(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          autofocus: false,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.arrow_forward,
                                color: AppColor.primary,
                              ), // Search button icon
                              onPressed: () {},
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {},
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h10,
                  Divider(color: Colors.grey.shade300),
                  AppSpacing.h10,
                  provider.deliveredOrders == null
                      ? LinearProgressIndicator()
                      : DataTable(
                          dataRowHeight: 70,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'SL',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Order ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Payment Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Order Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Action',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: List.generate(provider.deliveredOrders!.length, (
                            index,
                          ) {
                            return DataRow(
                              cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(
                                  Text(provider.deliveredOrders![index].id),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat("MMM d yyyy HH:mm:00").format(
                                      DateTime.parse(
                                        provider
                                            .deliveredOrders![index]
                                            .createdDate,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  provider.deliveredOrders![index].isPaid
                                      ? Container(
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text('Paid'),
                                        )
                                      : Container(
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text('Unpaid'),
                                        ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "₹${provider.deliveredOrders![index].getTotalAmount().toStringAsFixed(0)}",
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    provider
                                        .deliveredOrders![index]
                                        .orderStatus,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.visibility_outlined,
                                          color: AppColor.primary,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderDetailsScreen(
                                                    order: provider
                                                        .deliveredOrders![index],
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
