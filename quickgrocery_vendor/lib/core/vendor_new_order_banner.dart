import 'dart:async';

import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import 'order_lifecycle.dart';

/// Blinkit/Zepto-style top floating card for new vendor orders.
class VendorNewOrderBannerController {
  OverlayEntry? _entry;
  Timer? _autoHideTimer;
  final List<NewOrderBannerPayload> _orders = [];
  _BannerHostState? _hostState;

  static const _autoHideDuration = Duration(seconds: 8);

  bool get isVisible => _entry != null;

  void showOrUpdate(
    BuildContext context, {
    required List<NewOrderBannerPayload> orders,
    required VoidCallback onDismiss,
    required void Function(OrderModel order) onViewOrder,
    required VoidCallback onViewAll,
    required void Function(OrderModel order) onAssignDriver,
    required Future<void> Function(OrderModel order) onAcceptOrder,
    required Future<void> Function(OrderModel order) onRejectOrder,
  }) {
    for (final o in orders) {
      if (!_orders.any((e) => e.orderId == o.orderId)) {
        _orders.add(o);
      }
    }
    if (_orders.isEmpty) return;

    void rebuild() => _hostState?.rebuildBanner();

    if (_entry == null) {
      _entry = OverlayEntry(
        builder: (ctx) => _BannerHost(
          onReady: (state) {
            _hostState = state;
            rebuild();
          },
          builder: (ctx, animation) => _buildBanner(
            ctx,
            animation: animation,
            onDismiss: () {
              _dismiss(onDismiss);
            },
            onViewOrder: (order) {
              _dismiss(onDismiss);
              onViewOrder(order);
            },
            onViewAll: () {
              _dismiss(onDismiss);
              onViewAll();
            },
            onAssignDriver: (order) {
              _dismiss(onDismiss);
              onAssignDriver(order);
            },
            onAcceptOrder: (order) async {
              await onAcceptOrder(order);
              _dismiss(onDismiss);
            },
            onRejectOrder: (order) async {
              await onRejectOrder(order);
              _dismiss(onDismiss);
            },
          ),
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(_entry!);
    } else {
      rebuild();
    }

    _resetAutoHide(onDismiss);
  }

  void _resetAutoHide(VoidCallback onDismiss) {
    _autoHideTimer?.cancel();
    final hasPendingAction = _orders.any((o) => o.needsVendorAction);
    if (hasPendingAction) return;
    _autoHideTimer = Timer(_autoHideDuration, () => _dismiss(onDismiss));
  }

  void _dismiss(VoidCallback onDismiss) {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
    _orders.clear();
    _hostState = null;
    _entry?.remove();
    _entry = null;
    onDismiss();
  }

  void dispose() {
    _autoHideTimer?.cancel();
    _entry?.remove();
    _entry = null;
    _orders.clear();
    _hostState = null;
  }

  Widget _buildBanner(
    BuildContext context, {
    required Animation<double> animation,
    required VoidCallback onDismiss,
    required void Function(OrderModel order) onViewOrder,
    required VoidCallback onViewAll,
    required void Function(OrderModel order) onAssignDriver,
    required Future<void> Function(OrderModel order) onAcceptOrder,
    required Future<void> Function(OrderModel order) onRejectOrder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;
    final slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final card = _orders.length == 1
        ? _SingleOrderBanner(
            payload: _orders.first,
            isDark: isDark,
            onDismiss: onDismiss,
            onViewOrder: () => onViewOrder(_orders.first.order),
            onAssignDriver: _orders.first.canAssignDriver
                ? () => onAssignDriver(_orders.first.order)
                : null,
            onAcceptOrder: _orders.first.needsVendorAction
                ? () => onAcceptOrder(_orders.first.order)
                : null,
            onRejectOrder: _orders.first.needsVendorAction
                ? () => onRejectOrder(_orders.first.order)
                : null,
          )
        : _StackedOrdersBanner(
            count: _orders.length,
            isDark: isDark,
            onDismiss: onDismiss,
            onViewAll: onViewAll,
          );

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: animation,
          child: Material(
            color: Colors.transparent,
            child: card,
          ),
        ),
      ),
    );
  }
}

class NewOrderBannerPayload {
  const NewOrderBannerPayload({
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.itemCount,
    required this.receivedAt,
    required this.order,
    required this.canAssignDriver,
    required this.needsVendorAction,
  });

  final String orderId;
  final String customerName;
  final double amount;
  final int itemCount;
  final DateTime receivedAt;
  final OrderModel order;
  final bool canAssignDriver;
  final bool needsVendorAction;

  factory NewOrderBannerPayload.fromOrder(
    OrderModel order,
    String vendorId,
    OrderService orderService,
  ) {
    final vendorItems =
        order.products.where((p) => p.vendorId == vendorId).toList();
    final itemCount = vendorItems.fold<int>(0, (sum, p) => sum + p.itemCount);
    final amount = vendorItems.fold<double>(
      0,
      (sum, p) => sum + p.price * p.itemCount,
    );
    final status = OrderLifecycle.resolveStatus({
      'status': order.modernStatus,
      'order_status': order.orderStatus,
      'isCancelled': order.isCancelled,
      'isDelivered': order.isDelivered,
    });
    return NewOrderBannerPayload(
      orderId: order.id,
      customerName: order.customerName,
      amount: amount,
      itemCount: itemCount,
      receivedAt: DateTime.now(),
      order: order,
      canAssignDriver: order.deliveryBoyId.isEmpty &&
          !order.isDelivered &&
          !order.isCancelled &&
          OrderLifecycle.isVendorAccepted(status),
      needsVendorAction: OrderLifecycle.isPendingVendorAction(status),
    );
  }
}

class _BannerHost extends StatefulWidget {
  const _BannerHost({
    required this.onReady,
    required this.builder,
  });

  final void Function(_BannerHostState state) onReady;
  final Widget Function(BuildContext context, Animation<double> animation)
      builder;

  @override
  State<_BannerHost> createState() => _BannerHostState();
}

class _BannerHostState extends State<_BannerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady(this);
    });
  }

  void rebuildBanner() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: SizedBox.expand(),
          ),
        ),
        widget.builder(context, _controller),
      ],
    );
  }
}

class _SingleOrderBanner extends StatelessWidget {
  const _SingleOrderBanner({
    required this.payload,
    required this.isDark,
    required this.onDismiss,
    required this.onViewOrder,
    this.onAssignDriver,
    this.onAcceptOrder,
    this.onRejectOrder,
  });

  final NewOrderBannerPayload payload;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onViewOrder;
  final VoidCallback? onAssignDriver;
  final Future<void> Function()? onAcceptOrder;
  final Future<void> Function()? onRejectOrder;

  static const _accentGreen = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final borderColor =
        isDark ? _accentGreen.withValues(alpha: 0.45) : _accentGreen.withValues(alpha: 0.25);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            decoration: BoxDecoration(
              color: _accentGreen.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🛒', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'New Order Received',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, color: textSecondary, size: 20),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Customer',
                  value: payload.customerName,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Order Amount',
                  value: '₹${payload.amount.toStringAsFixed(0)}',
                  textPrimary: _accentGreen,
                  textSecondary: textSecondary,
                  valueBold: true,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Items',
                  value: payload.itemCount == 1
                      ? '1 item'
                      : '${payload.itemCount} items',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Time',
                  value: _formatRelativeTime(payload.receivedAt),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 14),
                if (onAcceptOrder != null && onRejectOrder != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async => onAcceptOrder!(),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Accept Order',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async => onRejectOrder!(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reject Order',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewOrder,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentGreen,
                          side: const BorderSide(color: _accentGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (onAssignDriver != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onAssignDriver,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accentGreen,
                            side: const BorderSide(color: _accentGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Assign Driver',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedOrdersBanner extends StatelessWidget {
  const _StackedOrdersBanner({
    required this.count,
    required this.isDark,
    required this.onDismiss,
    required this.onViewAll,
  });

  final int count;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onViewAll;

  static const _accentGreen = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentGreen.withValues(alpha: isDark ? 0.45 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🛒', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count New Orders',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, color: textSecondary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You have $count waiting orders that need your attention.',
              style: TextStyle(fontSize: 14, color: textSecondary, height: 1.35),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onViewAll,
              style: FilledButton.styleFrom(
                backgroundColor: _accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View All',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textPrimary,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatRelativeTime(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inSeconds < 45) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
