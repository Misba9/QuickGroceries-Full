/// Which Orders module page is active.
enum OrderModulePage {
  overview,
  newOrders,
  manage,
  refund,
}

extension OrderModulePageX on OrderModulePage {
  String get title {
    switch (this) {
      case OrderModulePage.overview:
        return 'Orders Dashboard';
      case OrderModulePage.newOrders:
        return 'New Orders';
      case OrderModulePage.manage:
        return 'Manage Orders';
      case OrderModulePage.refund:
        return 'Refund Requests';
    }
  }

  String? get subtitle {
    switch (this) {
      case OrderModulePage.overview:
        return 'KPIs, trends, and live operational insights';
      case OrderModulePage.newOrders:
        return 'Live incoming orders, dispatch queue, and rider assignment';
      case OrderModulePage.manage:
        return 'Search, filter, and manage every order in one place';
      case OrderModulePage.refund:
        return 'Refunds, disputes, and cancellation review';
    }
  }
}

/// Smart filters for the shared orders table ([OrderModulePage.manage]).
enum OrderQuickFilter {
  allOrders,
  pending,
  assigned,
  waiting,
  delivered,
  cancelled,
  cod,
  online,
  highValue,
  scheduled,
}

extension OrderQuickFilterX on OrderQuickFilter {
  String get label {
    switch (this) {
      case OrderQuickFilter.allOrders:
        return 'All Orders';
      case OrderQuickFilter.pending:
        return 'Pending';
      case OrderQuickFilter.assigned:
        return 'Assigned';
      case OrderQuickFilter.waiting:
        return 'Waiting';
      case OrderQuickFilter.delivered:
        return 'Delivered';
      case OrderQuickFilter.cancelled:
        return 'Cancelled';
      case OrderQuickFilter.cod:
        return 'COD';
      case OrderQuickFilter.online:
        return 'Online';
      case OrderQuickFilter.highValue:
        return 'High Value';
      case OrderQuickFilter.scheduled:
        return 'Scheduled';
    }
  }
}
