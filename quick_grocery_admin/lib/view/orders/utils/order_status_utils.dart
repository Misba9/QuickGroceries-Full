import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';

enum OrderDisplayStatus {
  newOrder,
  accepted,
  assigned,
  pickedUp,
  nearCustomer,
  waiting,
  pending,
  packing,
  outForDelivery,
  delivered,
  cancelled,
  refund,
}

class OrderStatusStyle {
  const OrderStatusStyle({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color border;
}

class OrderStatusUtils {
  OrderStatusUtils._();

  static OrderDisplayStatus resolve(OrderModel order) {
    final s = order.orderStatus.toLowerCase().trim();

    if (order.isCancelled) {
      if (s.contains('refund') || s.contains('dispute')) {
        return OrderDisplayStatus.refund;
      }
      return OrderDisplayStatus.cancelled;
    }
    if (order.isDelivered || s.contains('deliver')) {
      return OrderDisplayStatus.delivered;
    }
    if (s.contains('near') || s.contains('arriv')) {
      return OrderDisplayStatus.nearCustomer;
    }
    if (s.contains('picked') || s.contains('pickup')) {
      return OrderDisplayStatus.pickedUp;
    }
    if (order.deliveryBoyId.isNotEmpty ||
        s.contains('assigned') ||
        s.contains('rider')) {
      return OrderDisplayStatus.assigned;
    }
    if (s.contains('accept')) {
      return OrderDisplayStatus.accepted;
    }
    if (s.contains('wait') || s.contains('confirm')) {
      return OrderDisplayStatus.waiting;
    }
    if (s.contains('pack') || s.contains('ready')) {
      return OrderDisplayStatus.packing;
    }
    if (s.contains('out') || s.contains('way')) {
      return OrderDisplayStatus.outForDelivery;
    }
    if (s.contains('new') || s.isEmpty) {
      return OrderDisplayStatus.newOrder;
    }
    if (s.contains('pending')) {
      return OrderDisplayStatus.pending;
    }
    return OrderDisplayStatus.pending;
  }

  static OrderStatusStyle styleFor(OrderDisplayStatus status) {
    switch (status) {
      case OrderDisplayStatus.newOrder:
        return const OrderStatusStyle(
          label: 'New',
          icon: Icons.fiber_new_rounded,
          background: Color(0xFFFFF9E6),
          foreground: Color(0xFFB45309),
          border: Color(0xFFFCD34D),
        );
      case OrderDisplayStatus.accepted:
        return const OrderStatusStyle(
          label: 'Accepted',
          icon: Icons.thumb_up_alt_outlined,
          background: Color(0xFFEFF6FF),
          foreground: Color(0xFF1D4ED8),
          border: Color(0xFF93C5FD),
        );
      case OrderDisplayStatus.assigned:
        return const OrderStatusStyle(
          label: 'Assigned',
          icon: Icons.two_wheeler,
          background: Color(0xFFF5F3FF),
          foreground: Color(0xFF6D28D9),
          border: Color(0xFFC4B5FD),
        );
      case OrderDisplayStatus.pickedUp:
        return const OrderStatusStyle(
          label: 'Picked Up',
          icon: Icons.shopping_bag_outlined,
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFC2410C),
          border: Color(0xFFFDBA74),
        );
      case OrderDisplayStatus.nearCustomer:
        return const OrderStatusStyle(
          label: 'Near Customer',
          icon: Icons.near_me,
          background: Color(0xFFECFEFF),
          foreground: Color(0xFF0E7490),
          border: Color(0xFF67E8F9),
        );
      case OrderDisplayStatus.waiting:
        return const OrderStatusStyle(
          label: 'Waiting',
          icon: Icons.hourglass_top_rounded,
          background: Color(0xFFEFF6FF),
          foreground: Color(0xFF1D4ED8),
          border: Color(0xFF93C5FD),
        );
      case OrderDisplayStatus.pending:
        return const OrderStatusStyle(
          label: 'Pending',
          icon: Icons.schedule_rounded,
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFEA580C),
          border: Color(0xFFFED7AA),
        );
      case OrderDisplayStatus.packing:
        return const OrderStatusStyle(
          label: 'Packing',
          icon: Icons.inventory_2_outlined,
          background: Color(0xFFF8FAFC),
          foreground: Color(0xFF475569),
          border: Color(0xFFCBD5E1),
        );
      case OrderDisplayStatus.outForDelivery:
        return const OrderStatusStyle(
          label: 'Out for delivery',
          icon: Icons.delivery_dining_rounded,
          background: Color(0xFFECFEFF),
          foreground: Color(0xFF0E7490),
          border: Color(0xFF67E8F9),
        );
      case OrderDisplayStatus.delivered:
        return const OrderStatusStyle(
          label: 'Delivered',
          icon: Icons.check_circle_outline_rounded,
          background: Color(0xFFECFDF5),
          foreground: Color(0xFF047857),
          border: Color(0xFF6EE7B7),
        );
      case OrderDisplayStatus.cancelled:
        return const OrderStatusStyle(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          background: Color(0xFFFEF2F2),
          foreground: Color(0xFFB91C1C),
          border: Color(0xFFFECACA),
        );
      case OrderDisplayStatus.refund:
        return const OrderStatusStyle(
          label: 'Refunded',
          icon: Icons.currency_exchange_rounded,
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFFB45309),
          border: Color(0xFFFCD34D),
        );
    }
  }

  static OrderStatusStyle styleForOrder(OrderModel order) =>
      styleFor(resolve(order));
}
