import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/vendor_new_order_banner.dart';
import '../../../core/vendor_notification_hub.dart';
import '../../../core/vendor_notification_store.dart';
import '../../../core/vendor_order_notification_controller.dart';
import '../../../models/order_model.dart';
import '../../../models/vendor_model.dart';
import '../../../services/order_service.dart';
import '../../orders/order_detail_screen.dart';
import '../../orders/widgets/assign_rider_sheet.dart';

/// Listens to vendor orders and surfaces sound, banner, and badge updates.
class VendorOrderRealtimeHost extends StatefulWidget {
  const VendorOrderRealtimeHost({
    super.key,
    required this.vendor,
    required this.notifications,
    required this.onViewAllOrders,
    required this.child,
  });

  final VendorModel vendor;
  final VendorOrderNotificationController notifications;
  final VoidCallback onViewAllOrders;
  final Widget child;

  @override
  State<VendorOrderRealtimeHost> createState() =>
      _VendorOrderRealtimeHostState();
}

class _VendorOrderRealtimeHostState extends State<VendorOrderRealtimeHost> {
  final OrderService _orders = OrderService();
  final VendorNewOrderBannerController _banner = VendorNewOrderBannerController();
  StreamSubscription<List<OrderModel>>? _subscription;
  bool _alertScheduled = false;

  @override
  void initState() {
    super.initState();
    VendorNotificationHub.instance.register(
      vendorId: widget.vendor.id,
      notifications: widget.notifications,
      onFcmNewOrder: _handleFcmNewOrder,
      onRequestBannerRefresh: _scheduleAlertIfNeeded,
    );
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant VendorOrderRealtimeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendor.id != widget.vendor.id) {
      _subscription?.cancel();
      VendorNotificationHub.instance.register(
        vendorId: widget.vendor.id,
        notifications: widget.notifications,
        onFcmNewOrder: _handleFcmNewOrder,
        onRequestBannerRefresh: _scheduleAlertIfNeeded,
      );
      _subscribe();
    }
  }

  Future<void> _handleFcmNewOrder(Map<String, dynamic> data) async {
    final type = data['type']?.toString() ?? '';
    final orderId = data['orderId']?.toString() ?? '';
    if (orderId.isEmpty) return;

    if (type == 'order_cancelled') {
      await _handleFcmCancellation(data, orderId);
      return;
    }

    if (type != 'new_order') return;
    if (widget.notifications.hasBeenNotified(orderId)) {
      if (kDebugMode) {
        debugPrint('[VendorNotify] FCM skipped duplicate orderId=$orderId');
      }
      return;
    }

    final order = await _orders.getOrderById(orderId);
    if (order == null || !mounted) return;

    widget.notifications.injectNewOrderFromRemote(
      order,
      vendorId: widget.vendor.id,
    );

    await VendorNotificationStore.writeLocal(
      vendorId: widget.vendor.id,
      type: 'new_order',
      title: '🛒 New Order',
      body: 'New order from ${order.customerName}',
      orderId: order.id,
      customerName: order.customerName,
      amount: _orders.getVendorOrderTotal(order, widget.vendor.id),
    );

    _scheduleAlertIfNeeded();
  }

  Future<void> _handleFcmCancellation(
    Map<String, dynamic> data,
    String orderId,
  ) async {
    final statusKey = '$orderId:cancelled';
    if (widget.notifications.hasBeenNotified(statusKey)) return;

    final order = await _orders.getOrderById(orderId);
    if (order == null || !mounted) return;

    widget.notifications.markOrderNotified(statusKey);

    await VendorNotificationStore.writeLocal(
      vendorId: widget.vendor.id,
      type: 'order_cancelled',
      title: '❌ Order Cancelled',
      body: data['message']?.toString() ??
          'Order #${orderId.substring(0, 8)} has been cancelled.',
      orderId: orderId,
      customerName: order.customerName,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showCancellationPopup(orderId, order.customerName);
    });
  }

  void _showCancellationPopup(String orderId, String customerName) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.red.shade50,
        leading: const Icon(Icons.cancel, color: Colors.red),
        content: Text(
          '❌ Order Cancelled\n'
          'Order #${orderId.substring(0, 8)} cancelled by $customerName.',
        ),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              widget.onViewAllOrders();
            },
            child: const Text('View Orders'),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 8), () {
      messenger?.hideCurrentMaterialBanner();
    });
  }

  void _subscribe() {
    _subscription = _orders
        .watchVendorOrders(widget.vendor.id)
        .listen(_onOrdersUpdated, onError: (_) {});
  }

  @override
  void dispose() {
    VendorNotificationHub.instance.unregister();
    _subscription?.cancel();
    _banner.dispose();
    super.dispose();
  }

  void _onOrdersUpdated(List<OrderModel> orders) {
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('[VendorNotify] Firestore orders updated count=${orders.length}');
    }
    widget.notifications.onOrdersUpdated(
      orders,
      vendorId: widget.vendor.id,
    );
    _scheduleAlertIfNeeded();
  }

  void _scheduleAlertIfNeeded() {
    final hasNewOrders = widget.notifications.pendingNewOrderCount > 0;
    final hasStatusAlert = widget.notifications.latestAlert != null &&
        widget.notifications.latestAlert!.type != VendorAlertType.newOrder;
    if (_alertScheduled || (!hasNewOrders && !hasStatusAlert)) return;

    _alertScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alertScheduled = false;
      if (!mounted) return;
      _showAlerts();
    });
  }

  void _showAlerts() {
    _showNewOrderBanner();
    _showStatusSnackBar();
  }

  void _showNewOrderBanner() async {
    final pending = widget.notifications.takePendingNewOrders();
    if (pending.isEmpty) return;

    final payloads = <NewOrderBannerPayload>[];
    for (final alert in pending) {
      if (alert.order == null) continue;
      if (widget.notifications.hasBeenNotified(alert.orderId)) continue;
      widget.notifications.markOrderNotified(alert.orderId);
      await VendorNotificationStore.writeLocal(
        vendorId: widget.vendor.id,
        type: 'new_order',
        title: '🛒 New Order',
        body: 'New order from ${alert.customerName}',
        orderId: alert.orderId,
        customerName: alert.customerName,
        amount: _orders.getVendorOrderTotal(alert.order!, widget.vendor.id),
      );
      payloads.add(
        NewOrderBannerPayload.fromOrder(
          alert.order!,
          widget.vendor.id,
          _orders,
        ),
      );
    }
    if (payloads.isEmpty) return;

    if (kDebugMode) {
      debugPrint('[VendorNotify] banner shown orders=${payloads.length}');
    }

    _banner.showOrUpdate(
      context,
      orders: payloads,
      onDismiss: () {},
      onViewOrder: _openOrderDetail,
      onViewAll: widget.onViewAllOrders,
      onAssignDriver: _openAssignDriver,
      onAcceptOrder: _acceptOrder,
      onRejectOrder: _rejectOrder,
    );
  }

  Future<void> _acceptOrder(OrderModel order) async {
    await _orders.acceptOrder(order.id, vendorId: widget.vendor.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order accepted'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _rejectOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject order?'),
        content: const Text(
          'The customer will be notified and the order will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _orders.rejectOrder(order.id, vendorId: widget.vendor.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order rejected')),
    );
  }

  void _openOrderDetail(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(
          order: order,
          vendor: widget.vendor,
        ),
      ),
    );
  }

  void _openAssignDriver(OrderModel order) {
    AssignRiderSheet.show(
      context,
      order: order,
      orderService: _orders,
    );
  }

  void _showStatusSnackBar() {
    final alert = widget.notifications.latestAlert;
    if (alert == null || alert.type == VendorAlertType.newOrder) return;

    widget.notifications.clearLatest();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (alert.type == VendorAlertType.cancelled) {
      messenger?.showMaterialBanner(
        MaterialBanner(
          backgroundColor: Colors.red.shade50,
          leading: const Icon(Icons.cancel, color: Colors.red),
          content: Text(alert.message),
          actions: [
            TextButton(
              onPressed: () => messenger.hideCurrentMaterialBanner(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Future.delayed(const Duration(seconds: 6), () {
        messenger?.hideCurrentMaterialBanner();
      });
      return;
    }

    messenger?.showSnackBar(
      SnackBar(
        content: Text(alert.message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
