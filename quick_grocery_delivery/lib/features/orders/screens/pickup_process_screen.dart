import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/features/orders/screens/delivery_process_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stage 5–6: rider accepted → reached store → picked up (live via OrderService stream).
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
    return Consumer<OrderService>(
      builder: (context, svc, _) {
        final live = svc.orderById(order.id) ?? order;
        final status = _statusId(live);
        final canReachStore = status == OrderLifecycle.riderAccepted ||
            status == OrderLifecycle.headingToStore;
        final canPickUp = status == OrderLifecycle.reachedStore;
        final pickedUp = status == OrderLifecycle.pickedUp ||
            status == OrderLifecycle.outForDelivery;

        return Scaffold(
          backgroundColor: GlobalVariables.background,
          appBar: AppBar(
            title: const Text('Pickup'),
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
                _SectionCard(
                  title: 'Customer',
                  icon: Icons.person_outline,
                  children: [
                    _InfoRow(label: 'Name', value: live.customerName),
                    _InfoRow(label: 'Phone', value: live.phone, isPhone: true),
                    _InfoRow(label: 'Delivery Address', value: live.address),
                  ],
                ),
                AppSpacing.h10,
                _SectionCard(
                  title: 'Vendor (Pickup)',
                  icon: Icons.storefront_outlined,
                  children: [
                    _InfoRow(
                      label: 'Name',
                      value: live.vendorName.isNotEmpty ? live.vendorName : 'Store',
                    ),
                    _InfoRow(
                      label: 'Phone',
                      value: live.vendorPhone,
                      isPhone: true,
                    ),
                    _InfoRow(
                      label: 'Pickup Address',
                      value: live.pickupAddress.isNotEmpty
                          ? live.pickupAddress
                          : 'Address not available',
                    ),
                  ],
                ),
                AppSpacing.h20,
                _ActionButton(
                  icon: Icons.navigation,
                  label: 'Navigate to Store',
                  color: Colors.orange.shade700,
                  onTap: () => _openStore(context, live),
                ),
                if (canReachStore) ...[
                  AppSpacing.h10,
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
                ],
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
                        Icon(Icons.check_circle, color: Colors.green.shade700),
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openStore(BuildContext context, OrderModel live) async {
    final ok = await DeliveryRouteUtils.openNavigation(
      lat: live.pickupLat,
      lng: live.pickupLng,
      address: live.pickupAddress,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store location not available')),
      );
    }
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
    if (live != null) {
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
    final label = OrderLifecycle.legacyLabel(status);
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
                  label,
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
  const _InfoRow({
    required this.label,
    required this.value,
    this.isPhone = false,
  });

  final String label;
  final String value;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: isPhone && display != '—'
                ? InkWell(
                    onTap: () => _callPhone(display),
                    child: Text(
                      display,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    display,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(
      scheme: 'tel',
      path: normalized.startsWith('+') ? normalized : '+91$normalized',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
              Icon(Icons.open_in_new, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
