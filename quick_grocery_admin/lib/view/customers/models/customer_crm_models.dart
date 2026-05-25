import 'package:quick_grocery_admin/model/customer_model.dart';

class CustomerOrderStats {
  const CustomerOrderStats({
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalSpend = 0,
    this.lastOrderAt,
  });

  final int totalOrders;
  final int completedOrders;
  final double totalSpend;
  final DateTime? lastOrderAt;

  static const empty = CustomerOrderStats();
}

class CustomerEnriched {
  const CustomerEnriched({
    required this.customer,
    required this.stats,
  });

  final CustomerModel customer;
  final CustomerOrderStats stats;

  String get displayId => customer.docId;
}

class CustomerListSummary {
  const CustomerListSummary({
    this.totalCustomers = 0,
    this.activeToday = 0,
    this.newToday = 0,
    this.onlineNow = 0,
    this.totalRevenue = 0,
    this.repeatBuyers = 0,
  });

  final int totalCustomers;
  final int activeToday;
  final int newToday;
  final int onlineNow;
  final double totalRevenue;
  final int repeatBuyers;
}
