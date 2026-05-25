import 'package:quick_grocery_admin/model/order_model.dart';

/// Order ↔ vendor matching (orders store vendor_id on line items, not always top-level).
class VendorOrderUtils {
  VendorOrderUtils._();

  static bool belongsToVendor(OrderModel order, String vendorId) {
    if (vendorId.isEmpty) return false;
    if (order.products.any((p) => p.vendorId == vendorId)) return true;
    return false;
  }

  static bool belongsToVendorData(Map<String, dynamic> data, String vendorId) {
    if (vendorId.isEmpty) return false;
    final top = data['vendor_id']?.toString() ?? data['vendorId']?.toString();
    if (top == vendorId) return true;
    final vendorIds = data['vendorIds'];
    if (vendorIds is List && vendorIds.map((e) => e.toString()).contains(vendorId)) {
      return true;
    }
    final products = data['products'];
    if (products is! List) return false;
    for (final raw in products) {
      if (raw is! Map) continue;
      final id = raw['vendor_id']?.toString() ?? raw['vendorId']?.toString() ?? '';
      if (id == vendorId) return true;
    }
    return false;
  }

  static bool isCancelled(OrderModel order) =>
      order.isCancelled ||
      order.orderStatus.toLowerCase().contains('cancel');

  static bool isCompleted(OrderModel order) =>
      !isCancelled(order) &&
      (order.isDelivered ||
          order.orderStatus.toLowerCase().contains('deliver'));

  static bool isPending(OrderModel order) =>
      !isCancelled(order) && !isCompleted(order);

  static bool isActiveOrder(OrderModel order) => isPending(order);

  static String deliveryStatusLabel(OrderModel order) {
    if (isCancelled(order)) return 'Cancelled';
    if (order.isDelivered) return 'Delivered';
    if (order.deliveryBoyId.isNotEmpty) return 'Out for delivery';
    final s = order.orderStatus.toLowerCase();
    if (s.contains('pack')) return 'Packing';
    if (s.contains('accept') || s.contains('confirm')) return 'Confirmed';
    return 'Pending';
  }

  static DateTime? parseCreatedDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
