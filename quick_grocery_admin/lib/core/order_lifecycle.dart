/// Canonical quick-commerce order lifecycle for the admin app.
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
      default:
        return statusId;
    }
  }

  static String resolveFromOrder({
    required bool isCancelled,
    required bool isDelivered,
    String? modernStatus,
    String? legacyStatus,
  }) {
    if (isCancelled) return cancelled;
    if (isDelivered) return delivered;
    if (modernStatus != null && modernStatus.trim().isNotEmpty) {
      return modernStatus.trim();
    }
    return resolveStatus({'order_status': legacyStatus ?? ''});
  }

  static String resolveStatus(Map<String, dynamic> data) {
    if (data['isCancelled'] == true) {
      final modern = (data['status'] as String?)?.trim() ?? '';
      if (modern == vendorRejected) return vendorRejected;
      return cancelled;
    }
    if (data['isDelivered'] == true) return delivered;

    final modern = (data['status'] as String?)?.trim();
    if (modern != null && modern.isNotEmpty) return modern;

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

  static bool isVendorAccepted(String status) =>
      status == vendorAccepted || status == accepted;

  static bool isActive(String status) => !isTerminal(status);

  static bool isTerminal(String status) =>
      status == delivered ||
      status == cancelled ||
      status == vendorRejected;

  static bool isPending(String status) => status == pending;

  static bool isAssigned(String status) =>
      status == riderAssigned ||
      status == headingToStore ||
      status == pickedUp ||
      status == outForDelivery;
}
