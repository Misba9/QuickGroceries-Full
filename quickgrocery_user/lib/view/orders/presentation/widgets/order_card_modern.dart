import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

import '../../domain/order_models.dart';

class OrderCardModern extends StatelessWidget {
  const OrderCardModern({
    super.key,
    required this.order,
    required this.onTap,
  });

  final LiveOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final products = order.legacy.products;
    final dateLabel = order.createdAt.millisecondsSinceEpoch == 0
        ? ''
        : DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: surface.card,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: surface.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusPill(status: order.status),
                    const Spacer(),
                    if (dateLabel.isNotEmpty)
                      Text(
                        dateLabel,
                        style: TextStyle(
                          color: surface.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: products.isEmpty
                            ? Container(color: surface.subtle)
                            : CachedImage(url: products.first.image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            products.isEmpty
                                ? 'Order #${order.id}'
                                : (products.length == 1
                                    ? products.first.name
                                    : '${products.first.name} +${products.length - 1} more'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: surface.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.deliveryPartnerTip > 0
                                ? '${order.itemCount} items · ₹${order.total.toStringAsFixed(0)} · Tip ₹${order.deliveryPartnerTip.toStringAsFixed(0)}'
                                : '${order.itemCount} items · ₹${order.total.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: surface.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: surface.iconInactive),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final (Color bg, Color fg) = switch (status) {
      OrderStatus.orderPlaced => (
          surface.orderPending.withValues(alpha: 0.18),
          surface.orderPending,
        ),
      OrderStatus.deliveryAssigned => (
          surface.orderPacked.withValues(alpha: 0.18),
          surface.orderPacked,
        ),
      OrderStatus.outForDelivery => (
          surface.orderOutForDelivery.withValues(alpha: 0.18),
          surface.orderOutForDelivery,
        ),
      OrderStatus.delivered => (
          surface.orderDelivered.withValues(alpha: 0.18),
          surface.orderDelivered,
        ),
      OrderStatus.cancelled || OrderStatus.vendorRejected => (
          surface.orderCancelled.withValues(alpha: 0.18),
          surface.orderCancelled,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
