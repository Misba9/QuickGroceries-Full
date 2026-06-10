import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_bill_summary_section.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/services/invoice_service.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/widgets/admin_text_selection.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.order});
  final OrderModel order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    Provider.of<OrderService>(
      context,
      listen: false,
    ).getCustomer(widget.order.uuid);
    // Get vendor from first product if available
    if (widget.order.products.isNotEmpty) {
      Provider.of<OrderService>(
        context,
        listen: false,
      ).getVendor(widget.order.products.first.vendorId);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);

    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Column(
        children: [
          PrimaryAppBar(isBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Details Card
                  WrapperWidget(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Order ID & Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdminSelectableText(
                              'Order ID: ${widget.order.id}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.h10,
                            Text(
                              DateFormat("MMM d yyyy HH:mm:00").format(
                                DateTime.parse(widget.order.createdDate),
                              ),
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        // Status & Payment Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text('Status :'),
                                AppSpacing.w10,
                                Text(
                                  widget.order.orderStatus,
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                            AppSpacing.h10,
                            Row(
                              children: [
                                Text('Delivery Type :'),
                                AppSpacing.w10,
                                Text(
                                  widget.order.deliveryType,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h20,

                  // Order Items Table
                  WrapperWidget(
                    child: DataTable(
                      dataRowMinHeight: 80,
                      dataRowMaxHeight: 80,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'SL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Item details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'MRP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Selling Price',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Discount',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Quantity',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Total Paid',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: List.generate(widget.order.products.length, (
                        index,
                      ) {
                        final product = widget.order.products[index];
                        final itemTotal = product.lineTotal;
                        final unitPaid = product.price;
                        final unitMrp = product.slashedPrice > unitPaid + 0.01
                            ? product.slashedPrice
                            : unitPaid;
                        final discount =
                            (unitMrp - unitPaid) * product.itemCount;
                        return DataRow(
                          cells: [
                            DataCell(Text((index + 1).toString())),
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: product.image.isNotEmpty
                                        ? Image.network(
                                            product.image,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.image_not_supported,
                                                  );
                                                },
                                          )
                                        : Icon(Icons.image_not_supported),
                                  ),
                                  AppSpacing.w10,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppSpacing.h10,
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      AppSpacing.h5,
                                      Text('Qty : ${product.itemCount}'),
                                      Text(
                                        unitMrp > unitPaid + 0.01
                                            ? 'Unit: ₹${unitPaid.toStringAsFixed(0)}  MRP ₹${unitMrp.toStringAsFixed(0)}'
                                            : 'Unit: ₹${unitPaid.toStringAsFixed(0)}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text("₹${unitMrp.toStringAsFixed(2)}")),
                            DataCell(Text("₹${unitPaid.toStringAsFixed(2)}")),
                            DataCell(Text("₹${discount.toStringAsFixed(2)}")),
                            DataCell(Text("${product.itemCount}")),
                            DataCell(Text("₹${itemTotal.toStringAsFixed(2)}")),
                          ],
                        );
                      }),
                    ),
                  ),
                  AppSpacing.h20,

                  WrapperWidget(
                    child: OrderBillSummarySection(order: widget.order),
                  ),
                  AppSpacing.h20,

                  // Customer Information
                  provider.customer == null
                      ? LinearProgressIndicator()
                      : WrapperWidget(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset('assets/icons/user.svg'),
                                  AppSpacing.w10,
                                  Text(
                                    'Customer Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.h10,
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade100,
                                    backgroundImage:
                                        provider.customer!.image == ''
                                        ? null
                                        : NetworkImage(
                                            provider.customer!.image,
                                          ),
                                  ),
                                  AppSpacing.w10,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AdminSelectableText(
                                        provider.customer!.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('0 Orders'),
                                      AdminSelectableText(
                                        provider.customer!.phoneNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                  AppSpacing.h20,

                  // Shipping Address
                  WrapperWidget(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: SvgPicture.asset(
                                'assets/icons/location.svg',
                              ),
                            ),
                            AppSpacing.w10,
                            Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.h10,
                        AdminSelectableText(
                          'Customer : ${widget.order.customerName}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        AdminSelectableText('Contact : ${widget.order.phone}'),
                        AppSpacing.h10,
                        Row(
                          children: [
                            Icon(Icons.place, color: Colors.grey),
                            AppSpacing.w10,
                            Expanded(
                              child: AdminSelectableText(widget.order.address),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h20,

                  if (widget.order.deliverySlot != null)
                    WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Slot',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          AppSpacing.h10,
                          Text(
                            widget.order.deliverySlotLabel,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  if (widget.order.deliverySlot != null) AppSpacing.h20,

                  if (widget.order.deliveryInstructions != null &&
                      !widget.order.deliveryInstructions!.isEmpty)
                    WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          AppSpacing.h10,
                          ...widget.order.deliveryInstructions!
                              .displayLines()
                              .map((line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(line),
                                  )),
                        ],
                      ),
                    ),
                  if (widget.order.deliveryInstructions != null &&
                      !widget.order.deliveryInstructions!.isEmpty)
                    AppSpacing.h20,

                  // Vendor Information
                  provider.vendor == null
                      ? LinearProgressIndicator()
                      : WrapperWidget(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset('assets/icons/shop.svg'),
                                  AppSpacing.w10,
                                  Text(
                                    'Shop Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.h10,
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade100,
                                    backgroundImage: NetworkImage(
                                      provider.vendor!.shopImage,
                                    ),
                                  ),
                                  AppSpacing.w10,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AdminSelectableText(
                                        provider.vendor!.shopName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('2 Orders Served'),
                                      AdminSelectableText(
                                        provider.vendor!.phone,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      AppSpacing.h10,
                                      Row(
                                        children: [
                                          Icon(Icons.place, color: Colors.grey),
                                          AppSpacing.w10,
                                          SizedBox(
                                            width: 200,
                                            child: AdminSelectableText(
                                              provider.vendor!.shopAddress,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                  AppSpacing.h20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Print Invoice Button
                      ElevatedButton.icon(
                        onPressed: () {
                          InvoiceService.printInvoice(
                            order: widget.order,
                            customer: provider.customer,
                            vendor: provider.vendor,
                            context: context,
                          );
                        },
                        icon: Icon(Icons.print),
                        label: Text('Print receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      AppSpacing.w10,
                      // Share Invoice Button
                      ElevatedButton.icon(
                        onPressed: () {
                          InvoiceService.shareInvoice(
                            order: widget.order,
                            customer: provider.customer,
                            vendor: provider.vendor,
                            context: context,
                          );
                        },
                        icon: Icon(Icons.share),
                        label: Text('Share receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      AppSpacing.w10,
                      // Cancel Order Button
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Order'),
                              content: const Text(
                                'Do you want to cancel this order?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.cancellOrder(
                                      context,
                                      widget.order.id,
                                    );
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order cancelled'),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Yes',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            'Cancel Order',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
