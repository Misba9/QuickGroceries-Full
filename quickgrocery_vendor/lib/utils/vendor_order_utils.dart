import '../core/order_lifecycle.dart';
import '../models/order_model.dart';

/// Shared order matching, status buckets, and revenue rules (vendor + dashboard).
class VendorOrderUtils {
  VendorOrderUtils._();

  static String productVendorId(Map<String, dynamic> data) {
    return (data['vendor_id'] ?? data['vendorId'] ?? '').toString().trim();
  }

  static bool orderBelongsToVendor(OrderModel order, String vendorId) {
    if (vendorId.isEmpty) return false;
    if (order.products.any((p) => p.vendorId == vendorId)) return true;
    return false;
  }

  static bool orderDataBelongsToVendor(Map<String, dynamic> data, String vendorId) {
    if (vendorId.isEmpty) return false;
    final top = (data['vendor_id'] ?? data['vendorId'] ?? '').toString();
    if (top == vendorId) return true;
    final vendorIds = data['vendorIds'];
    if (vendorIds is List &&
        vendorIds.map((e) => e.toString()).contains(vendorId)) {
      return true;
    }
    final products = data['products'];
    if (products is! List) return false;
    for (final raw in products) {
      if (raw is Map) {
        final item = Map<String, dynamic>.from(raw);
        if (productVendorId(item) == vendorId) return true;
      }
    }
    return false;
  }

  static String normalizedStatus(OrderModel order) {
    if (order.isCancelled) return OrderLifecycle.cancelled;
    return OrderLifecycle.resolveStatus({
      'status': order.modernStatus,
      'order_status': order.orderStatus,
      'isCancelled': order.isCancelled,
      'isDelivered': order.isDelivered,
    });
  }

  /// UI filter chip id: All | waiting | confirmed | processing | shipped | delivered | cancelled
  static String statusBucket(OrderModel order) {
    final s = normalizedStatus(order);
    if (s == OrderLifecycle.vendorRejected || s == OrderLifecycle.cancelled) {
      return 'cancelled';
    }
    if (s == OrderLifecycle.delivered) return 'delivered';
    if (OrderLifecycle.isInTransit(s)) return 'shipped';
    if (s == OrderLifecycle.packing ||
        s == OrderLifecycle.readyForPickup ||
        s == OrderLifecycle.riderAssigned) {
      return 'processing';
    }
    if (OrderLifecycle.isVendorAccepted(s)) return 'confirmed';
    if (s == OrderLifecycle.pending) return 'waiting';
    return 'waiting';
  }

  static bool matchesFilter(OrderModel order, String filter) {
    if (filter == 'All') return true;
    return statusBucket(order) == filter;
  }

  static bool isCancelled(OrderModel order) =>
      order.isCancelled || normalizedStatus(order) == 'cancelled';

  static bool isCompleted(OrderModel order) {
    if (isCancelled(order)) return false;
    final s = normalizedStatus(order);
    return order.isDelivered ||
        s == 'delivered' ||
        order.orderStatus.toLowerCase().contains('deliver');
  }

  static bool isPending(OrderModel order) =>
      !isCancelled(order) && !isCompleted(order);

  static bool isActiveOrder(OrderModel order) => isPending(order);

  static bool countsForRevenue(OrderModel order) => isCompleted(order);

  static DateTime? parseCreatedDate(OrderModel order) {
    if (order.createdAt != null) return order.createdAt;
    final raw = order.createdDate.trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static double vendorRevenueFromOrder(OrderModel order, String vendorId) {
    if (!countsForRevenue(order)) return 0;
    double revenue = 0;
    var vendorUnits = 0;
    var totalUnits = 0;
    for (final p in order.products) {
      totalUnits += p.itemCount;
      if (p.vendorId == vendorId) {
        revenue += p.price * p.itemCount;
        vendorUnits += p.itemCount;
      }
    }
    if (totalUnits > 0 && order.deliveryCharge > 0 && vendorUnits > 0) {
      revenue += (order.deliveryCharge * vendorUnits) / totalUnits;
    }
    return revenue;
  }
}
