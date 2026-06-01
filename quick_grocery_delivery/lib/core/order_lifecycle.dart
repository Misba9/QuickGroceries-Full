/// Canonical quick-commerce order lifecycle for the delivery rider app.
class OrderLifecycle {
  OrderLifecycle._();

  static const pending = 'pending';
  static const vendorAccepted = 'vendor_accepted';
  static const vendorRejected = 'vendor_rejected';
  static const accepted = 'accepted';
  static const packing = 'packing';
  static const readyForPickup = 'ready_for_pickup';
  static const riderAssigned = 'rider_assigned';
  static const riderAccepted = 'rider_accepted';
  static const reachedStore = 'reached_store';
  static const headingToStore = 'heading_to_store';
  static const pickedUp = 'picked_up';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
  static const cancelledByCustomer = 'cancelled_by_customer';
  static const cancelledByVendor = 'cancelled_by_vendor';
  static const cancelledByRider = 'cancelled_by_rider';

  static bool isCancellationStatus(String status) =>
      status == cancelled ||
      status == cancelledByCustomer ||
      status == cancelledByVendor ||
      status == cancelledByRider ||
      status == vendorRejected;

  static bool isBeforePickup(String status) =>
      status != pickedUp &&
      status != outForDelivery &&
      status != delivered &&
      !isCancellationStatus(status);

  static String legacyLabel(String statusId) {
    switch (statusId) {
      case pending:
        return 'Pending';
      case vendorAccepted:
        return 'Vendor Accepted';
      case vendorRejected:
        return 'Vendor Rejected';
      case accepted:
        return 'Order Confirm';
      case packing:
        return 'Preparing';
      case readyForPickup:
        return 'Ready for Pickup';
      case riderAssigned:
        return 'Rider Assigned';
      case riderAccepted:
        return 'Rider Accepted';
      case reachedStore:
        return 'Reached Store';
      case headingToStore:
        return 'Going to Shop';
      case pickedUp:
        return 'Order Picked';
      case outForDelivery:
        return 'On the Way';
      case delivered:
        return 'Order Delivered';
      case cancelled:
        return 'cancelled';
      case cancelledByCustomer:
        return 'Cancelled by Customer';
      case cancelledByVendor:
        return 'Cancelled by Vendor';
      case cancelledByRider:
        return 'Cancelled by Rider';
      default:
        return statusId;
    }
  }

  static String resolveStatus(Map<String, dynamic> data) {
    final modern = (data['status'] as String?)?.trim() ?? '';
    if (modern.isNotEmpty && _knownStatuses.contains(modern)) return modern;

    if (data['isCancelled'] == true) {
      if (modern == vendorRejected) return vendorRejected;
      if (modern == cancelledByCustomer) return cancelledByCustomer;
      if (modern == cancelledByVendor) return cancelledByVendor;
      if (modern == cancelledByRider) return cancelledByRider;
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
    if (s.contains('way')) return outForDelivery;
    if (s.contains('picked')) return pickedUp;
    if (s.contains('reached') && s.contains('store')) return reachedStore;
    if (s.contains('going') || s.contains('shop')) return headingToStore;
    if (s.contains('rider') && s.contains('accept')) return riderAccepted;
    if (s.contains('rider') && s.contains('assign')) return riderAssigned;
    if (s.contains('ready')) return readyForPickup;
    if (s.contains('prepar') || s.contains('pack')) return packing;
    if (s.contains('reject')) return vendorRejected;
    if (s.contains('vendor') && s.contains('accept')) return vendorAccepted;
    if (s.contains('confirm') || s.contains('accept')) return vendorAccepted;
    if (s.contains('pending') || s.contains('waiting')) return pending;
    return pending;
  }

  static bool needsRiderAcceptance(String status) => status == riderAssigned;

  static bool isRiderAccepted(String status) => status == riderAccepted;

  static bool isPickupPhase(String status) =>
      status == riderAccepted ||
      status == reachedStore ||
      status == headingToStore;

  static bool isLiveTracking(String status) =>
      status == riderAccepted ||
      status == reachedStore ||
      status == headingToStore ||
      status == pickedUp ||
      status == outForDelivery;

  static bool isInTransit(String status) =>
      status == reachedStore ||
      status == headingToStore ||
      status == pickedUp ||
      status == outForDelivery;

  static bool isTerminal(String status) =>
      status == delivered || isCancellationStatus(status);

  static const _knownStatuses = {
    pending,
    vendorAccepted,
    vendorRejected,
    accepted,
    packing,
    readyForPickup,
    riderAssigned,
    riderAccepted,
    reachedStore,
    headingToStore,
    pickedUp,
    outForDelivery,
    delivered,
    cancelled,
    cancelledByCustomer,
    cancelledByVendor,
    cancelledByRider,
  };
}
