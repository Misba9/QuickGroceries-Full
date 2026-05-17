/// Sidebar route preset for orders management.
enum OrderListPreset {
  all,
  newToday,
  delivered,
  cancelled,
}

extension OrderListPresetX on OrderListPreset {
  String get title {
    switch (this) {
      case OrderListPreset.all:
        return 'All Orders';
      case OrderListPreset.newToday:
        return 'New Orders';
      case OrderListPreset.delivered:
        return 'Delivered Orders';
      case OrderListPreset.cancelled:
        return 'Cancelled Orders';
    }
  }

  String? get subtitle {
    switch (this) {
      case OrderListPreset.newToday:
        return 'Orders placed today';
      case OrderListPreset.delivered:
        return 'Successfully completed deliveries';
      case OrderListPreset.cancelled:
        return 'Cancelled and refunded orders';
      default:
        return 'Manage and track every order';
    }
  }
}

/// Horizontal filter pills on the orders table.
enum OrderQuickFilter {
  none,
  today,
  thisWeek,
  allOrders,
  cod,
  paid,
  highValue,
  delivered,
  cancelled,
}

extension OrderQuickFilterX on OrderQuickFilter {
  String get label {
    switch (this) {
      case OrderQuickFilter.none:
        return 'All';
      case OrderQuickFilter.today:
        return 'Today';
      case OrderQuickFilter.thisWeek:
        return 'This Week';
      case OrderQuickFilter.allOrders:
        return 'All Orders';
      case OrderQuickFilter.cod:
        return 'COD';
      case OrderQuickFilter.paid:
        return 'Paid';
      case OrderQuickFilter.highValue:
        return 'High Value';
      case OrderQuickFilter.delivered:
        return 'Delivered';
      case OrderQuickFilter.cancelled:
        return 'Cancelled';
    }
  }
}
