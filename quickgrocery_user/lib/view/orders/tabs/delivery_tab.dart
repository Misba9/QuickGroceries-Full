import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/order/order_line_display.dart';
import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';
import 'package:quickgrocery/view/orders/services/order_service.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

class DeliveryTab extends StatelessWidget {
  const DeliveryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderService>(
      builder: (context, p, _) {
        return RefreshIndicator(
          onRefresh: () => p.getOrders(),
          child: p.deliveredOrders.isEmpty
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
                            Text(context.l10n.noOrdersFound),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : DeliveredListWidget(orders: p.deliveredOrders),
        );
      },
    );
  }
}

class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    super.key,
    required this.width,
    required this.height,
    required this.image,
    required this.price,
    required this.hotel,
    required this.name,
    required this.product,
    required this.onReviewTap,
    required this.isRated,
    required this.rating,
  });

  final double width;
  final double height;
  final String image;
  final String price;
  final String hotel;
  final String name;
  final ProductModel product;
  final Function() onReviewTap;
  final double rating;
  final bool isRated;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.all(10),
      width: width,
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CachedImage(
                  url: image,
                  width: 80,
                  height: 80,
                  alignment: Alignment.topCenter,
                  fit: BoxFit.cover,
                  memCacheWidth: 160,
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
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: surface.success.withValues(alpha: 0.18),
                        ),
                        child: Center(
                          child: Text(
                            'Completed',
                            style: TextStyle(fontSize: 12, color: surface.success),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Divider(color: surface.border),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class OrderButton extends StatelessWidget {
  const OrderButton({
    super.key,
    required this.width,
    required this.label,
    required this.onTap,
  });

  final double width;
  final String label;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width / 2.5,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: surface.textPrimary),
          color: surface.card,
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: surface.textPrimary)),
        ),
      ),
    );
  }
}

class DeliveredListWidget extends StatelessWidget {
  final List<OrderModel> orders;

  const DeliveredListWidget({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<OrderService>(context);
    final width = MediaQuery.of(context).size.width;
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
                    leading: ClipOval(
                      child: CachedImage(
                        url: p.image,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        memCacheWidth: 80,
                      ),
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
                AppSpacing.h10,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    order.isRated
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(order.rating.toInt(), (
                              index,
                            ) {
                              return Icon(
                                index < order.rating
                                    ? Icons.star
                                    : Icons.star_border, // Yellow or Grey
                                color: index < order.rating
                                    ? Colors.amber
                                    : surface.iconInactive,
                                size: 25,
                              );
                            }),
                          )
                        : OrderButton(
                            width: width,
                            label: 'Write Review',
                            onTap: () {
                              p.showReviewDialog(
                                context,
                                p.deliveredOrders[0].id,
                              );
                            },
                          ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LandingScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: width / 2.5,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: surface.textPrimary,
                        ),
                        child: Center(
                          child: Text(
                            'Order Again',
                            style: TextStyle(color: surface.card),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
