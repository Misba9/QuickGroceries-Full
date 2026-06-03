import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/confirm_delivery_dialog.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/delivery_order_detail_panel.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/order_live_builder.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';

/// Customer delivery leg with live contact info and mark-delivered flow.
class DeliveryProcessScreen extends StatelessWidget {
  const DeliveryProcessScreen({super.key, required this.order});

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
        title: const Text('Deliver to Customer'),
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
              final isOutForDelivery =
                  status == OrderLifecycle.outForDelivery;
              final canStartDelivery =
                  status == OrderLifecycle.deliveryAssigned;
              final isDelivered =
                  status == OrderLifecycle.delivered || live.isDelivered;
              final reporting = svc.customerNotReachableOrderId == live.id;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusBanner(status: status, order: live),
                    AppSpacing.h15,
                    DeliveryOrderDetailPanel(
                      order: live,
                      showCustomerNotReachable: isOutForDelivery,
                      customerNotReachableLoading: reporting,
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
                    AppSpacing.h15,
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.payments_outlined,
                            label: 'Payment',
                            value: live.isPaid ? 'Paid online' : 'Collect COD',
                          ),
                        ),
                        AppSpacing.w10,
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.receipt_long,
                            label: 'Order',
                            value:
                                '#${live.id.length > 6 ? live.id.substring(0, 6) : live.id}',
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h20,
                    if (canStartDelivery)
                      _ActionButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'Start Delivery',
                        color: GlobalVariables.primary,
                        filled: true,
                        loading: svc.deliveryActionOrderId == live.id,
                        onTap: svc.deliveryActionOrderId == live.id
                            ? null
                            : () => _startOutForDelivery(context, svc, live.id),
                      ),
                    if (isOutForDelivery) ...[
                      AppSpacing.h10,
                      _ActionButton(
                        icon: Icons.check_circle_outline,
                        label: 'Mark as Delivered',
                        color: Colors.green.shade700,
                        filled: true,
                        loading: svc.deliveryActionOrderId == live.id,
                        onTap: svc.deliveryActionOrderId == live.id
                            ? null
                            : () => _confirmDelivered(context, svc, live.id),
                      ),
                    ],
                    if (isDelivered) ...[
                      AppSpacing.h10,
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade700),
                                AppSpacing.w10,
                                const Text(
                                  'Order delivered',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            if (live.deliveryDurationSec != null) ...[
                              AppSpacing.h10,
                              Text(
                                'Duration: ${DeliveryRouteUtils.formatDuration((live.deliveryDurationSec! / 60).round())}',
                              ),
                            ],
                            if (live.distanceTravelledKm != null)
                              Text(
                                'Distance: ${DeliveryRouteUtils.formatDistance(live.distanceTravelledKm)}',
                              ),
                          ],
                        ),
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

  Future<void> _startOutForDelivery(
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

  Future<void> _confirmDelivered(
    BuildContext context,
    OrderService svc,
    String orderId,
  ) async {
    final order = svc.orderById(orderId);
    if (order != null && order.payment.requiresCodCollection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collect payment first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final confirmed = await showConfirmDeliveryDialog(context);
    if (!confirmed || !context.mounted) return;
    await svc.markDelivered(context, orderId);
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
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line),
            ),
          ),
        ],
      ),
    );
  }
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
          const Icon(Icons.delivery_dining, color: Colors.white, size: 36),
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
                  order.customerName,
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
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
