import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';

enum OrderDisplayStatus {
  pending,
  waiting,
  packing,
  outForDelivery,
  delivered,
  cancelled,
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
    if (order.isCancelled) return OrderDisplayStatus.cancelled;
    if (order.isDelivered) return OrderDisplayStatus.delivered;

    final s = order.orderStatus.toLowerCase().trim();
    if (s.contains('cancel')) return OrderDisplayStatus.cancelled;
    if (s.contains('deliver') && !s.contains('out')) {
      return OrderDisplayStatus.delivered;
    }
    if (s.contains('out') ||
        s.contains('way') ||
        s.contains('rider') ||
        s.contains('picked')) {
      return OrderDisplayStatus.outForDelivery;
    }
    if (s.contains('pack') || s.contains('pick') || s.contains('ready')) {
      return OrderDisplayStatus.packing;
    }
    if (s.contains('wait') || s.contains('confirm') || s.contains('accept')) {
      return OrderDisplayStatus.waiting;
    }
    if (s.contains('pending') || s.isEmpty) {
      return OrderDisplayStatus.pending;
    }
    return OrderDisplayStatus.pending;
  }

  static OrderStatusStyle styleFor(OrderDisplayStatus status) {
    switch (status) {
      case OrderDisplayStatus.pending:
        return OrderStatusStyle(
          label: 'Pending',
          icon: Icons.schedule_rounded,
          background: const Color(0xFFFFF7ED),
          foreground: const Color(0xFFC2410C),
          border: const Color(0xFFFDBA74),
        );
      case OrderDisplayStatus.waiting:
        return OrderStatusStyle(
          label: 'Waiting',
          icon: Icons.hourglass_top_rounded,
          background: const Color(0xFFEFF6FF),
          foreground: const Color(0xFF1D4ED8),
          border: const Color(0xFF93C5FD),
        );
      case OrderDisplayStatus.packing:
        return OrderStatusStyle(
          label: 'Packing',
          icon: Icons.inventory_2_outlined,
          background: const Color(0xFFF5F3FF),
          foreground: const Color(0xFF6D28D9),
          border: const Color(0xFFC4B5FD),
        );
      case OrderDisplayStatus.outForDelivery:
        return OrderStatusStyle(
          label: 'Out for delivery',
          icon: Icons.delivery_dining_rounded,
          background: const Color(0xFFECFEFF),
          foreground: const Color(0xFF0E7490),
          border: const Color(0xFF67E8F9),
        );
      case OrderDisplayStatus.delivered:
        return OrderStatusStyle(
          label: 'Delivered',
          icon: Icons.check_circle_outline_rounded,
          background: const Color(0xFFECFDF5),
          foreground: const Color(0xFF047857),
          border: const Color(0xFF6EE7B7),
        );
      case OrderDisplayStatus.cancelled:
        return OrderStatusStyle(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          background: const Color(0xFFFEF2F2),
          foreground: const Color(0xFFB91C1C),
          border: const Color(0xFFFECACA),
        );
    }
  }

  static OrderStatusStyle styleForOrder(OrderModel order) =>
      styleFor(resolve(order));
}
