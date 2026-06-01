import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/delivery_otp_sheet.dart';
import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';

/// Stage 8–9: delivery leg + OTP verification before `delivered`.
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
    return Consumer<OrderService>(
      builder: (context, svc, _) {
        final live = svc.orderById(order.id) ?? order;
        final status = _statusId(live);
        final isOutForDelivery = status == OrderLifecycle.outForDelivery;
        final isPickedUp = status == OrderLifecycle.pickedUp;
        final isDelivered =
            status == OrderLifecycle.delivered || live.isDelivered;

        return Scaffold(
          backgroundColor: GlobalVariables.background,
          appBar: AppBar(
            title: const Text('Deliver to Customer'),
            backgroundColor: GlobalVariables.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(status: status, order: live),
                AppSpacing.h15,
                _SectionCard(
                  title: 'Customer',
                  icon: Icons.person_outline,
                  children: [
                    _InfoRow(label: 'Name', value: live.customerName),
                    _InfoRow(label: 'Phone', value: live.phone),
                    _InfoRow(label: 'Address', value: live.address),
                  ],
                ),
                if (live.deliveryInstructionLines.isNotEmpty) ...[
                  AppSpacing.h10,
                  _SectionCard(
                    title: 'Instructions',
                    icon: Icons.note_alt_outlined,
                    children: live.deliveryInstructionLines
                        .map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(line),
                            ))
                        .toList(),
                  ),
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
                if (isPickedUp)
                  _ActionButton(
                    icon: Icons.local_shipping_outlined,
                    label: 'Start Delivery to Customer',
                    color: GlobalVariables.primary,
                    filled: true,
                    loading: svc.deliveryActionOrderId == live.id,
                    onTap: svc.deliveryActionOrderId == live.id
                        ? null
                        : () => _startOutForDelivery(context, svc, live.id),
                  ),
                if (isOutForDelivery) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.amber.shade900),
                        AppSpacing.w10,
                        Expanded(
                          child: Text(
                            'Customer received a 4-digit OTP. Enter it to complete delivery.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h10,
                  _ActionButton(
                    icon: Icons.navigation,
                    label: 'Navigate to Customer',
                    color: Colors.blue.shade700,
                    onTap: () => _openCustomer(context, live),
                  ),
                  AppSpacing.h10,
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Delivered',
                    color: Colors.green.shade700,
                    filled: true,
                    loading: svc.deliveryActionOrderId == live.id,
                    onTap: svc.deliveryActionOrderId == live.id
                        ? null
                        : () => _confirmDelivered(context, svc, live),
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
                              style: TextStyle(fontWeight: FontWeight.w800),
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
          ),
        );
      },
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

  Future<void> _openCustomer(BuildContext context, OrderModel live) async {
    final ok = await DeliveryRouteUtils.openNavigation(
      lat: live.latitude,
      lng: live.longitude,
      address: live.address,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer location not available')),
      );
    }
  }

  Future<void> _confirmDelivered(
    BuildContext context,
    OrderService svc,
    OrderModel live,
  ) async {
    final otp = await showDeliveryOtpSheet(
      context,
      customerName: live.customerName,
    );
    if (otp == null || otp.length != 4 || !context.mounted) return;
    await svc.markDelivered(context, live.id, otp: otp);
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: GlobalVariables.primary),
              AppSpacing.w10,
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          AppSpacing.h10,
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
    if (filled) {
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

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              AppSpacing.w10,
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
