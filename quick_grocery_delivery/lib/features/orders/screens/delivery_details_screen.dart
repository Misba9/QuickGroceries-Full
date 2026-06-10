import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/confirm_delivery_dialog.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/delivery_order_detail_panel.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/order_earnings_card.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/order_live_builder.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/payment_status_card.dart';
import 'package:quick_grocery_delivery/features/payment/screens/order_collect_payment_screen.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';

/// Unified delivery hub after accept — status, payment, contacts, actions.
class DeliveryDetailsScreen extends StatelessWidget {
  const DeliveryDetailsScreen({super.key, required this.order});

  final OrderModel order;

  String _statusId(OrderModel o) => OrderLifecycle.resolveStatus({
        'status': o.modernStatus,
        'order_status': o.orderStatus,
        'isCancelled': o.isCancelled,
        'isDelivered': o.isDelivered,
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalVariables.background,
      appBar: AppBar(
        title: const Text('Delivery Details'),
        backgroundColor: GlobalVariables.primary,
        foregroundColor: Colors.white,
      ),
      body: OrderLiveBuilder(
        orderId: order.id,
        seed: order,
        builder: (context, live) {
          return Consumer<OrderService>(
            builder: (context, svc, _) {
              final status = _statusId(live);
              final isAssigned = status == OrderLifecycle.deliveryAssigned;
              final isOutForDelivery =
                  status == OrderLifecycle.outForDelivery;
              final isDelivered =
                  live.isDelivered || status == OrderLifecycle.delivered;
              final needsPayment = live.payment.requiresCodCollection;
              final online = live.payment.isOnlinePaid;
              final busy = svc.deliveryActionOrderId == live.id ||
                  svc.pickupActionOrderId == live.id;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderStatusCard(status: status),
                    AppSpacing.h10,
                    PaymentStatusCard(order: live),
                    AppSpacing.h10,
                    OrderEarningsCard(order: live),
                    AppSpacing.h10,
                    DeliveryOrderDetailPanel(
                      order: live,
                      showCustomerNotReachable: isOutForDelivery,
                      customerNotReachableLoading:
                          svc.customerNotReachableOrderId == live.id,
                      onCustomerNotReachable: isOutForDelivery
                          ? () => svc.reportCustomerNotReachable(
                                context,
                                live.id,
                              )
                          : null,
                    ),
                    if (live.deliveryInstructionLines.isNotEmpty) ...[
                      AppSpacing.h10,
                      _InstructionsCard(lines: live.deliveryInstructionLines),
                    ],
                    if (live.routeDistanceKm != null &&
                        live.routeDistanceKm! > 0) ...[
                      AppSpacing.h10,
                      _RouteSummaryCard(order: live),
                    ],
                    AppSpacing.h20,
                    if (isAssigned && live.hasVendorCoordinates)
                      _PrimaryButton(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Navigate To Store',
                        onTap: busy
                            ? null
                            : () => DeliveryRouteUtils.openNavigation(
                                  lat: live.pickupLat,
                                  lng: live.pickupLng,
                                  coordinatesOnly: true,
                                ),
                      ),
                    if (isAssigned) ...[
                      AppSpacing.h10,
                      _PrimaryButton(
                        icon: Icons.store,
                        label: 'Reached Store',
                        filled: true,
                        loading: svc.pickupActionOrderId == live.id,
                        onTap: busy
                            ? null
                            : () => svc.markReachedStore(live.id),
                      ),
                      AppSpacing.h10,
                      _PrimaryButton(
                        icon: Icons.inventory_2_outlined,
                        label: 'Picked Up Order',
                        color: Colors.green.shade700,
                        filled: true,
                        loading: svc.pickupActionOrderId == live.id,
                        onTap: busy ? null : () => svc.markPickedUp(live.id),
                      ),
                      AppSpacing.h10,
                      _PrimaryButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'Start Delivery',
                        filled: true,
                        loading: svc.deliveryActionOrderId == live.id,
                        onTap: busy
                            ? null
                            : () => _startDelivery(context, svc, live.id),
                      ),
                    ],
                    if (isOutForDelivery) ...[
                      if (live.hasCustomerCoordinates) ...[
                        AppSpacing.h10,
                        _PrimaryButton(
                          icon: Icons.navigation_rounded,
                          label: 'Navigate To Customer',
                          onTap: busy
                              ? null
                              : () => DeliveryRouteUtils.openNavigation(
                                    lat: live.latitude,
                                    lng: live.longitude,
                                    coordinatesOnly: true,
                                  ),
                        ),
                      ],
                      if (needsPayment && !online) ...[
                        AppSpacing.h10,
                        _PrimaryButton(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Collect Payment',
                          color: Colors.amber.shade800,
                          filled: true,
                          onTap: busy
                              ? null
                              : () => _openCollectPayment(context, live),
                        ),
                      ],
                      AppSpacing.h10,
                      _PrimaryButton(
                        icon: Icons.check_circle_outline,
                        label: 'Mark as Delivered',
                        color: Colors.green.shade700,
                        filled: true,
                        loading: svc.deliveryActionOrderId == live.id,
                        onTap: busy
                            ? null
                            : () => _markDelivered(context, svc, live),
                      ),
                    ],
                    if (isDelivered)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Order completed',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startDelivery(
    BuildContext context,
    OrderService svc,
    String orderId,
  ) async {
    await svc.markOutForDelivery(orderId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Out for delivery — live tracking active'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openCollectPayment(BuildContext context, OrderModel live) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderCollectPaymentScreen(order: live),
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment collected — you can deliver now')),
      );
    }
  }

  Future<void> _markDelivered(
    BuildContext context,
    OrderService svc,
    OrderModel live,
  ) async {
    if (live.payment.requiresCodCollection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collect payment before delivery.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final confirmed = await showConfirmDeliveryDialog(context);
    if (!confirmed || !context.mounted) return;
    await svc.markDelivered(context, live.id);
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final label = OrderLifecycle.legacyLabel(status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route estimate',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.h5,
                  Text(
                    DeliveryRouteUtils.formatDistance(order.routeDistanceKm),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected time',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.h5,
                  Text(
                    DeliveryRouteUtils.formatDuration(
                      order.expectedDeliveryMinutes,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
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

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l),
                ))
            .toList(),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.filled = false,
    this.loading = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: color ?? GlobalVariables.primary,
          )
        : OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50));

    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w700));

    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: child,
        style: style as ButtonStyle?,
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: child,
    );
  }
}
