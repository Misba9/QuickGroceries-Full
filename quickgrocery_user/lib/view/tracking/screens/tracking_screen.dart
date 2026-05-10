// Legacy tracking screen — preserved as a thin shim that forwards to the
// new realtime [OrderTrackingScreen]. The old constructor signature
// (`orderStatus`, `id` (=deliveryBoyId), `order`) is kept verbatim so the
// existing call-sites in processing_tab/cancelled_tab keep working.
import 'package:flutter/material.dart';
import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';

class TrackinScreen extends StatelessWidget {
  const TrackinScreen({
    super.key,
    required this.orderStatus,
    required this.id,
    required this.order,
  });

  /// Legacy field — kept so existing callers compile. The new tracking
  /// screen reads status live from Firestore.
  final String orderStatus;

  /// Legacy field — was the delivery-boy id. The new tracking screen
  /// hydrates rider info via the order document, so we do not need this
  /// directly any more.
  final String id;

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return OrderTrackingScreen(orderId: order.id);
  }
}
