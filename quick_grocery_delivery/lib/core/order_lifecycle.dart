/// Simplified order lifecycle for the delivery rider app.
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

  /// Legacy aliases used in older client code paths.
  static const pending = orderPlaced;
  static const riderAssigned = deliveryAssigned;
  static const riderAccepted = deliveryAssigned;
  static const pickedUp = outForDelivery;
  static const reachedStore = deliveryAssigned;
  static const headingToStore = deliveryAssigned;

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

  static bool isCancellationStatus(String status) {
    final s = normalizeStatus(status);
    return s == cancelled ||
        s == cancelledByCustomer ||
        s == cancelledByVendor ||
        s == cancelledByRider;
  }

  static bool isBeforePickup(String status) {
    final s = normalizeStatus(status);
    return s == orderPlaced || s == deliveryAssigned;
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
      case cancelledByCustomer:
        return 'Cancelled by Customer';
      case cancelledByVendor:
        return 'Cancelled by Vendor';
      case cancelledByRider:
        return 'Cancelled by Rider';
      case cancelled:
        return 'cancelled';
      default:
        return statusId;
    }
  }

  static String resolveStatus(Map<String, dynamic> data) {
    final modern = (data['status'] as String?)?.trim() ?? '';
    if (modern.isNotEmpty) return normalizeStatus(modern);

    if (data['isCancelled'] == true) {
      final by = (data['cancelledBy'] as String?)?.toLowerCase() ?? '';
      if (by == 'customer') return cancelledByCustomer;
      if (by == 'vendor') return cancelledByVendor;
      if (by == 'rider' || by == 'driver') return cancelledByRider;
      return cancelled;
    }
    if (data['isDelivered'] == true) return delivered;

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

  static bool needsRiderAcceptance(String status) =>
      normalizeStatus(status) == deliveryAssigned;

  static bool isRiderAccepted(String status) {
    final s = normalizeStatus(status);
    return s == deliveryAssigned || s == outForDelivery;
  }

  static bool isPickupPhase(String status) => false;

  static bool isLiveTracking(String status) =>
      normalizeStatus(status) == outForDelivery;

  static bool isActiveDelivery(String status) {
    final s = normalizeStatus(status);
    return s == deliveryAssigned || s == outForDelivery;
  }

  static bool isInTransit(String status) =>
      normalizeStatus(status) == outForDelivery;

  static bool isTerminal(String status) {
    final s = normalizeStatus(status);
    return s == delivered || isCancellationStatus(s);
  }
}
