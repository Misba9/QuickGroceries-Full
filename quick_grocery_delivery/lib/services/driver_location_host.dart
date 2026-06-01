import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/services/delivery_trip_tracker.dart';
import 'package:quick_grocery_delivery/services/driver_location_publisher.dart';

/// Keeps live GPS publishing in sync with active deliveries (5s → Firestore).
class DriverLocationHost extends StatefulWidget {
  const DriverLocationHost({super.key, required this.child});

  final Widget child;

  @override
  State<DriverLocationHost> createState() => _DriverLocationHostState();
}

class _DriverLocationHostState extends State<DriverLocationHost> {
  final DriverLocationPublisher _publisher = DriverLocationPublisher();
  String? _lastOrderId;

  @override
  void initState() {
    super.initState();
    _publisher.onPosition = (lat, lng) {
      if (DeliveryTripTracker.instance.isTracking) {
        DeliveryTripTracker.instance.onPosition(lat, lng);
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publisher.start();
    });
  }

  @override
  void dispose() {
    _publisher.dispose();
    super.dispose();
  }

  void _syncActiveOrder(OrderService orders) {
    final orderId = orders.activeTrackingOrderId;
    if (orderId == _lastOrderId) return;
    _lastOrderId = orderId;
    _publisher.setActiveOrderId(orderId);

    if (orderId != null) {
      final order = orders.orderById(orderId);
      if (order != null) {
        final st = OrderLifecycle.resolveStatus({
          'status': order.modernStatus,
          'order_status': order.orderStatus,
          'isCancelled': order.isCancelled,
          'isDelivered': order.isDelivered,
        });
        if (st == OrderLifecycle.outForDelivery &&
            DeliveryTripTracker.instance.orderId != orderId) {
          DeliveryTripTracker.instance.start(orderId);
        }
      }
    } else {
      DeliveryTripTracker.instance.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>();
    _syncActiveOrder(orders);
    return widget.child;
  }
}
