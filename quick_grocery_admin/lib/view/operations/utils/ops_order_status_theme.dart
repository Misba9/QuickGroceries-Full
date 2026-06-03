import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/order_lifecycle.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';

/// Dashboard status palette (ops queue).
enum OpsQueueStatus {
  waiting,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  other,
}

abstract final class OpsOrderStatusTheme {
  static OpsQueueStatus resolve(Map<String, dynamic> d) {
    if (OpsFirestoreHelpers.isCancelled(d)) {
      return OpsQueueStatus.cancelled;
    }
    if (OpsFirestoreHelpers.isDelivered(d)) {
      return OpsQueueStatus.delivered;
    }
    final status = OrderLifecycle.resolveFromOrderData(d);
    switch (status) {
      case OrderLifecycle.orderPlaced:
        return OpsQueueStatus.waiting;
      case OrderLifecycle.deliveryAssigned:
        return OpsQueueStatus.preparing;
      case OrderLifecycle.outForDelivery:
        return OpsQueueStatus.outForDelivery;
      case OrderLifecycle.delivered:
        return OpsQueueStatus.delivered;
      default:
        return OpsQueueStatus.other;
    }
  }

  static String label(OpsQueueStatus status) {
    switch (status) {
      case OpsQueueStatus.waiting:
        return 'Waiting';
      case OpsQueueStatus.confirmed:
        return 'Confirmed';
      case OpsQueueStatus.preparing:
        return 'Assigned';
      case OpsQueueStatus.outForDelivery:
        return 'Out for Delivery';
      case OpsQueueStatus.delivered:
        return 'Delivered';
      case OpsQueueStatus.cancelled:
        return 'Cancelled';
      case OpsQueueStatus.other:
        return 'In progress';
    }
  }

  static ({Color bg, Color fg, Color border}) colors(OpsQueueStatus status) {
    switch (status) {
      case OpsQueueStatus.waiting:
        return (
          bg: const Color(0xFFFFF7ED),
          fg: const Color(0xFFEA580C),
          border: const Color(0xFFFDBA74),
        );
      case OpsQueueStatus.confirmed:
        return (
          bg: const Color(0xFFEFF6FF),
          fg: const Color(0xFF1D4ED8),
          border: const Color(0xFF93C5FD),
        );
      case OpsQueueStatus.preparing:
        return (
          bg: const Color(0xFFF5F3FF),
          fg: const Color(0xFF6D28D9),
          border: const Color(0xFFC4B5FD),
        );
      case OpsQueueStatus.outForDelivery:
        return (
          bg: const Color(0xFFFEFCE8),
          fg: const Color(0xFFA16207),
          border: const Color(0xFFFDE047),
        );
      case OpsQueueStatus.delivered:
        return (
          bg: const Color(0xFFECFDF5),
          fg: const Color(0xFF047857),
          border: const Color(0xFF6EE7B7),
        );
      case OpsQueueStatus.cancelled:
        return (
          bg: const Color(0xFFFEF2F2),
          fg: const Color(0xFFB91C1C),
          border: const Color(0xFFFECACA),
        );
      case OpsQueueStatus.other:
        return (
          bg: const Color(0xFFF8FAFC),
          fg: const Color(0xFF475569),
          border: const Color(0xFFCBD5E1),
        );
    }
  }
}
