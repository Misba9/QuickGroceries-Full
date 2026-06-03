/// Simplified order lifecycle for the admin app.
class OrderLifecycle {
  OrderLifecycle._();

  static const orderPlaced = 'order_placed';
  static const deliveryAssigned = 'delivery_assigned';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
  static const cancelledByCustomer = 'cancelled_by_customer';
  static const cancelledByVendor = 'cancelled_by_vendor';
  static const cancelledByRider = 'cancelled_by_rider';

  static const pending = orderPlaced;
  static const riderAssigned = deliveryAssigned;

  static String normalizeStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s.isEmpty) return orderPlaced;
    switch (s) {
      case orderPlaced:
      case deliveryAssigned:
      case outForDelivery:
      case delivered:
      case cancelled:
      case cancelledByCustomer:
      case cancelledByVendor:
      case cancelledByRider:
        return s;
      case 'pending':
      case 'vendor_accepted':
      case 'accepted':
      case 'packing':
      case 'ready_for_pickup':
        return orderPlaced;
      case 'rider_assigned':
      case 'rider_accepted':
        return deliveryAssigned;
      case 'picked_up':
      case 'reached_store':
      case 'heading_to_store':
        return outForDelivery;
      case 'vendor_rejected':
        return cancelledByVendor;
      default:
        return orderPlaced;
    }
  }

  static String legacyLabel(String statusId) {
    switch (normalizeStatus(statusId)) {
      case orderPlaced:
        return 'Order Placed';
      case deliveryAssigned:
        return 'Delivery Partner Assigned';
      case outForDelivery:
        return 'Out For Delivery';
      case delivered:
        return 'Order Delivered';
      case cancelledByVendor:
        return 'Cancelled by Vendor';
      case cancelled:
        return 'cancelled';
      default:
        return statusId;
    }
  }

  /// Resolve from a raw Firestore order map (ops dashboard).
  static String resolveFromOrderData(Map<String, dynamic> data) =>
      _resolve(data);

  /// Resolve from [OrderModel] fields (orders UI).
  static String resolveFromOrder({
    required bool isCancelled,
    required bool isDelivered,
    String? modernStatus,
    String? legacyStatus,
  }) {
    return _resolve({
      'isCancelled': isCancelled,
      'isDelivered': isDelivered,
      'status': modernStatus,
      'order_status': legacyStatus,
    });
  }

  static String _resolve(Map<String, dynamic> data) {
    if (data['isCancelled'] == true) {
      final modern = (data['status'] as String?)?.trim() ?? '';
      if (modern == cancelledByVendor || modern == 'vendor_rejected') {
        return cancelledByVendor;
      }
      final by = (data['cancelledBy'] as String?)?.toLowerCase() ?? '';
      if (by == 'vendor') return cancelledByVendor;
      if (by == 'customer') return cancelledByCustomer;
      if (by == 'rider' || by == 'driver') return cancelledByRider;
      return cancelled;
    }
    if (data['isDelivered'] == true) return delivered;
    final modern = (data['status'] as String?)?.trim();
    if (modern != null && modern.isNotEmpty) return normalizeStatus(modern);
    final s = (data['order_status'] as String?)?.toLowerCase() ?? '';
    if (s.contains('cancel')) return cancelled;
    if (s.contains('deliver')) return delivered;
    if (s.contains('way') || s.contains('out for') || s.contains('picked')) {
      return outForDelivery;
    }
    if (s.contains('rider') || s.contains('assign') || s.contains('delivery partner')) {
      return deliveryAssigned;
    }
    if (s.contains('pending') || s.contains('waiting') || s.contains('placed')) {
      return orderPlaced;
    }
    return orderPlaced;
  }
}
