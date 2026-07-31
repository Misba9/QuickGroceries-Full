import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/order/order_line_display.dart';
import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/view/orders/services/order_service.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class CancelledTab extends StatelessWidget {
  const CancelledTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderService>(
      builder: (context, p, _) {
        return RefreshIndicator(
          onRefresh: () => p.getOrders(),
          child: p.cancellOrders.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LottieBuilder.asset('assets/lottie/no_orders.json'),
                            AppSpacing.h10,
                            Text(context.l10n.noCancelledOrdersFound),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : CancelledOrderListWidget(orders: p.cancellOrders),
        );
      },
    );
  }
}

class CancelledCard extends StatelessWidget {
  const CancelledCard({
    super.key,
    required this.height,
    required this.width,
    required this.image,
    required this.price,
    required this.hotel,
    required this.name,
  });

  final double width;
  final double height;
  final String image;
  final String price;
  final String hotel;

  final String name;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      height: height * .15,
      width: width,
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Image.network(
                  image,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return AppLoading.center;
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    } else {
                      return AppLoading.center;
                    }
                  },
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: surface.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Qty: $hotel",
                    style: TextStyle(color: surface.textMuted, fontSize: 12),
                  ),
                  SizedBox(height: height * .03),
                  Row(
                    children: [
                      Text(
                        '₹$price',
                        style: TextStyle(
                          color: surface.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: width * .04),
                      Container(
                        width: width * .20,
                        height: width * .08,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: surface.danger.withValues(alpha: 0.18),
                        ),
                        child: Center(
                          child: Text(
                            'Cancelled',
                            style: TextStyle(fontSize: 12, color: surface.danger),
                          ),
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
    );
  }
}

class CancelledOrderListWidget extends StatelessWidget {
  final List<OrderModel> orders;

  const CancelledOrderListWidget({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    if (orders.isEmpty) {
      return Center(child: Text(context.l10n.noOrdersFoundPeriod));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        double totalAmount = 0;
        int totalQty = 0;

        for (var item in order.products) {
          totalAmount += item.lineTotal;
          totalQty += item.itemCount;
        }
        totalAmount += order.deliveryCharge;

        return Card(
          color: surface.card,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order ID: ${order.id}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.products.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(p.image),
                    ),
                    title: Text(p.name),
                    subtitle: Text(orderLinePaidQtySummary(p)),
                    trailing: Text(
                      "₹${p.lineTotal.toStringAsFixed(0)}",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      25,
                      (index) => Container(
                        width: 10,
                        height: 1,
                        color: surface.border,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${context.l10n.totalItemsLabel} $totalQty'),
                    Text(context.l10n.deliveryChargeLabel(order.deliveryCharge.toStringAsFixed(0))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${context.l10n.statusLabel} ${order.orderStatus}'),
                    Text(
                      "Total: ₹${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // AppSpacing.h10,
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     order.orderStatus != 'Waiting'
                //         ? Container(
                //             width: width / 2.5,
                //             padding: const EdgeInsets.all(8),
                //             decoration: BoxDecoration(
                //               borderRadius: BorderRadius.circular(8),
                //               border: Border.all(
                //                 color: Colors.grey,
                //               ),
                //               color: Colors.white,
                //             ),
                //             child: Center(
                //               child: Text(
                //                 'cancell',
                //                 style: const TextStyle(
                //                   color: Colors.grey,
                //                 ),
                //               ),
                //             ),
                //           )
                //         : OrderButton(
                //             width: width,
                //             label: 'Cancel Order',
                //             onTap: () {
                //               Navigator.push(
                //                   context,
                //                   MaterialPageRoute(
                //                       builder: (context) => CancelOrder(
                //                             id: order.id,
                //                           )));
                //             },
                //           ),
                //     GestureDetector(
                //       onTap: () {
                //         Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //                 builder: (context) => TrackinScreen(
                //                       order: order,
                //                       id: order.deliveryBoyId,
                //                       orderStatus: order.orderStatus,
                //                     )));
                //       },
                //       child: Container(
                //         width: width / 2.5,
                //         padding: const EdgeInsets.all(8),
                //         decoration: BoxDecoration(
                //           borderRadius: BorderRadius.circular(8),
                //           color: AppColor.primary,
                //         ),
                //         child: const Center(
                //           child: Text(
                //             'Track Order',
                //             style: TextStyle(
                //               color: Colors.white,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // )
              ],
            ),
          ),
        );
      },
    );
  }
}
