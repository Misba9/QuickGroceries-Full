import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/features/orders/screens/delivery_process_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/delivery_order_detail_panel.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/order_live_builder.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';

/// Pickup leg: reached store → picked up (live order + vendor contact).
class PickupProcessScreen extends StatelessWidget {
  const PickupProcessScreen({super.key, required this.order});

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
        title: const Text('Pickup'),
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
              final canReachStore = status == OrderLifecycle.riderAccepted ||
                  status == OrderLifecycle.headingToStore;
              final canPickUp = status == OrderLifecycle.reachedStore;
              final pickedUp = status == OrderLifecycle.pickedUp ||
                  status == OrderLifecycle.outForDelivery;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusBanner(status: status, order: live),
                    AppSpacing.h15,
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.social_distance,
                            label: 'Distance',
                            value: DeliveryRouteUtils.formatDistance(
                              live.routeDistanceKm,
                            ),
                          ),
                        ),
                        AppSpacing.w10,
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.schedule,
                            label: 'Expected Time',
                            value: DeliveryRouteUtils.formatDuration(
                              live.expectedDeliveryMinutes,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h15,
                    DeliveryOrderDetailPanel(
                      order: live,
                      showCustomerNotReachable: false,
                    ),
                    AppSpacing.h20,
                    if (canReachStore)
                      _ActionButton(
                        icon: Icons.store,
                        label: 'Reached Store',
                        color: GlobalVariables.primary,
                        filled: true,
                        loading: svc.pickupActionOrderId == live.id,
                        onTap: svc.pickupActionOrderId == live.id
                            ? null
                            : () => _reachedStore(context, svc, live.id),
                      ),
                    if (canPickUp) ...[
                      AppSpacing.h10,
                      _ActionButton(
                        icon: Icons.inventory_2_outlined,
                        label: 'Picked Up Order',
                        color: Colors.green.shade700,
                        filled: true,
                        loading: svc.pickupActionOrderId == live.id,
                        onTap: svc.pickupActionOrderId == live.id
                            ? null
                            : () => _pickedUp(context, svc, live.id),
                      ),
                    ],
                    if (pickedUp) ...[
                      AppSpacing.h15,
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade700),
                            AppSpacing.w10,
                            const Expanded(
                              child: Text(
                                'Order picked up — proceed to customer delivery.',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h10,
                      _ActionButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'Go to Delivery',
                        color: Colors.blue.shade700,
                        filled: true,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeliveryProcessScreen(order: live),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _reachedStore(
    BuildContext context,
    OrderService svc,
    String orderId,
  ) async {
    await svc.markReachedStore(orderId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as reached store'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickedUp(
    BuildContext context,
    OrderService svc,
    String orderId,
  ) async {
    await svc.markPickedUp(orderId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order picked up'),
        backgroundColor: Colors.green,
      ),
    );
    final live = svc.orderById(orderId);
    if (live != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryProcessScreen(order: live),
        ),
      );
    }
  }
}

class RiderAcceptedScreen extends PickupProcessScreen {
  const RiderAcceptedScreen({super.key, required super.order});
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.order});

  final String status;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GlobalVariables.primary,
            GlobalVariables.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Colors.white, size: 36),
          AppSpacing.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  OrderLifecycle.legacyLabel(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Order #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GlobalVariables.primary, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
