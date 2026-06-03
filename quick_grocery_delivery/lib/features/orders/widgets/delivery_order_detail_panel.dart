import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/utils/delivery_contact_utils.dart';
import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';

/// Customer + vendor contact cards, timeline, and safety actions.
class DeliveryOrderDetailPanel extends StatelessWidget {
  const DeliveryOrderDetailPanel({
    super.key,
    required this.order,
    this.showCustomerCard = true,
    this.showVendorCard = true,
    this.showTimeline = true,
    this.showCustomerNotReachable = false,
    this.customerNotReachableLoading = false,
    this.onCustomerNotReachable,
  });

  final OrderModel order;
  final bool showCustomerCard;
  final bool showVendorCard;
  final bool showTimeline;
  final bool showCustomerNotReachable;
  final bool customerNotReachableLoading;
  final VoidCallback? onCustomerNotReachable;

  String get _storeLabel {
    if (order.storeName.trim().isNotEmpty) return order.storeName.trim();
    if (order.vendorName.trim().isNotEmpty) return order.vendorName.trim();
    return 'Store';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTimeline) ...[
          DeliveryOrderTimeline(order: order),
          AppSpacing.h15,
        ],
        if (showCustomerCard) ...[
          _CustomerContactCard(order: order),
          AppSpacing.h10,
        ],
        if (showVendorCard) ...[
          _VendorContactCard(
            order: order,
            storeLabel: _storeLabel,
          ),
          AppSpacing.h10,
        ],
        if (showCustomerNotReachable && onCustomerNotReachable != null) ...[
          OutlinedButton.icon(
            onPressed:
                customerNotReachableLoading ? null : onCustomerNotReachable,
            icon: customerNotReachableLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.phone_missed_outlined),
            label: const Text('Customer Not Reachable'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class DeliveryOrderTimeline extends StatelessWidget {
  const DeliveryOrderTimeline({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        label: 'Order Placed',
        time: DateTime.tryParse(order.createdDate),
        done: true,
      ),
      _TimelineStep(
        label: 'Delivery Partner Assigned',
        time: order.acceptedAt,
        done: order.acceptedAt != null,
      ),
      _TimelineStep(
        label: 'Out For Delivery',
        time: order.outForDeliveryAt,
        done: order.outForDeliveryAt != null,
      ),
      _TimelineStep(
        label: 'Delivered',
        time: order.deliveredAt,
        done: order.deliveredAt != null || order.isDelivered,
      ),
    ];

    return _SectionShell(
      title: 'Order timeline',
      icon: Icons.timeline_outlined,
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(
              step: steps[i],
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.time,
    required this.done,
  });

  final String label;
  final DateTime? time;
  final bool done;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, h:mm a');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done
                      ? GlobalVariables.primary
                      : Colors.grey.shade300,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.done
                        ? GlobalVariables.primary.withValues(alpha: 0.4)
                        : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: step.done ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (step.time != null)
                    Text(
                      fmt.format(step.time!.toLocal()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    )
                  else
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
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

class _CustomerContactCard extends StatelessWidget {
  const _CustomerContactCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final phone = order.phone.trim();
    return _SectionShell(
      title: 'Customer',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailLine(label: 'Name', value: order.customerName),
          _CopyablePhoneLine(phone: phone),
          _CopyableAddressLine(address: order.address),
          AppSpacing.h10,
          _ContactActionRow(
            actions: [
              _ContactAction(
                icon: Icons.phone,
                label: 'Call Customer',
                color: Colors.green.shade700,
                onTap: () => DeliveryContactUtils.callPhone(context, phone),
              ),
              _ContactAction(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => DeliveryContactUtils.openWhatsApp(context, phone),
              ),
              _ContactAction(
                icon: Icons.navigation,
                label: 'Navigate',
                color: Colors.blue.shade700,
                onTap: () => _navigateCustomer(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateCustomer(BuildContext context) async {
    final ok = await DeliveryRouteUtils.openNavigation(
      lat: order.latitude,
      lng: order.longitude,
      address: order.address,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer location not available')),
      );
    }
  }
}

class _VendorContactCard extends StatelessWidget {
  const _VendorContactCard({
    required this.order,
    required this.storeLabel,
  });

  final OrderModel order;
  final String storeLabel;

  @override
  Widget build(BuildContext context) {
    final phone = order.vendorPhone.trim();
    final address = order.pickupAddress.trim().isNotEmpty
        ? order.pickupAddress.trim()
        : 'Address not available';

    return _SectionShell(
      title: 'Vendor',
      icon: Icons.storefront_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailLine(
            label: 'Vendor Name',
            value: order.vendorName.isNotEmpty ? order.vendorName : '—',
          ),
          _DetailLine(label: 'Store Name', value: storeLabel),
          _CopyablePhoneLine(phone: phone, unavailableLabel: 'Vendor phone unavailable'),
          _CopyableAddressLine(
            address: address,
            label: 'Store Address',
          ),
          AppSpacing.h10,
          _ContactActionRow(
            actions: [
              _ContactAction(
                icon: Icons.phone,
                label: 'Call Vendor',
                color: Colors.orange.shade800,
                onTap: () => DeliveryContactUtils.callPhone(
                  context,
                  phone,
                  unavailableMessage: 'Vendor phone number unavailable',
                ),
              ),
              _ContactAction(
                icon: Icons.navigation,
                label: 'Navigate Store',
                color: Colors.deepOrange,
                onTap: () => _navigateStore(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateStore(BuildContext context) async {
    final ok = await DeliveryRouteUtils.openNavigation(
      lat: order.pickupLat,
      lng: order.pickupLng,
      address: order.pickupAddress,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store location not available')),
      );
    }
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
          child,
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyablePhoneLine extends StatelessWidget {
  const _CopyablePhoneLine({
    required this.phone,
    this.unavailableLabel = 'Customer phone number unavailable',
  });

  final String phone;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final display = phone.isNotEmpty ? phone : unavailableLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              'Phone',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: phone.isEmpty
                  ? null
                  : () => DeliveryContactUtils.copyText(
                        context,
                        phone,
                        successLabel: 'Number',
                      ),
              child: Text(
                display,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: phone.isEmpty ? Colors.grey : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableAddressLine extends StatelessWidget {
  const _CopyableAddressLine({
    required this.address,
    this.label = 'Delivery Address',
  });

  final String address;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: address.trim().isEmpty
                  ? null
                  : () => DeliveryContactUtils.copyText(
                        context,
                        address,
                        successLabel: 'Address',
                      ),
              child: Text(
                address.trim().isEmpty ? '—' : address.trim(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactAction {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _ContactActionRow extends StatelessWidget {
  const _ContactActionRow({required this.actions});

  final List<_ContactAction> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions
          .map(
            (a) => Material(
              color: a.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: a.onTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.icon, size: 18, color: a.color),
                      const SizedBox(width: 6),
                      Text(
                        a.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: a.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
