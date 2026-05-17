import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_status_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderChartPoint {
  const OrderChartPoint(this.label, this.value);
  final String label;
  final double value;
}

class OrderAnalyticsSnapshot {
  const OrderAnalyticsSnapshot({
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.revenue,
    required this.revenueTrendPct,
    required this.ordersTrendPct,
  });

  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double revenue;
  final double revenueTrendPct;
  final double ordersTrendPct;
}

class OrderService extends ChangeNotifier {
  CustomerModel? customer;
  VendorModel? vendor;
  AddressModel? address;
  List<OrderModel>? orders;
  List<OrderModel>? newOrders;
  List<OrderModel>? cancelledOrders;
  List<OrderModel>? deliveredOrders;

  bool isLoading = false;
  String searchQuery = '';
  OrderQuickFilter quickFilter = OrderQuickFilter.allOrders;
  OrderListPreset listPreset = OrderListPreset.all;
  int pageSize = 15;
  int visibleCount = 15;

  final TextEditingController searchController = TextEditingController();

  List<OrderModel>? _allOrdersCache;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void setListPreset(OrderListPreset preset) {
    listPreset = preset;
    visibleCount = pageSize;
    notifyListeners();
  }

  void setQuickFilter(OrderQuickFilter filter) {
    quickFilter = filter;
    visibleCount = pageSize;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value.trim().toLowerCase();
    visibleCount = pageSize;
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    setSearch('');
  }

  void loadMore() {
    visibleCount += pageSize;
    notifyListeners();
  }

  Future<void> getCustomer(String id) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(id)
          .get();
      if (!snapshot.exists) return;
      customer = CustomerModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        id,
      );
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> cancellOrder(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(id).update({
        'isCancelled': true,
        'order_status': 'cancelled',
      });
      await getOrders();
      if (context.mounted) Navigator.pop(context);
      notifyListeners();
    } catch (e) {
      debugPrint('cancel order: $e');
    }
  }

  Future<void> assignDeliveryBoy(String orderId, String deliveryBoyId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'deliveryBoyId': deliveryBoyId,
        'order_status': 'rider_assigned',
      });
      await getOrders();
    } catch (e) {
      debugPrint('assign delivery: $e');
      rethrow;
    }
  }

  Future<void> getVendor(String id) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(id)
          .get();
      if (!snapshot.exists) return;
      vendor = VendorModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        id,
      );
      notifyListeners();
    } catch (e) {}
  }

  Future<void> getAddress(String id) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('address')
          .doc(id)
          .get();
      address = AddressModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        id,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching address: $e');
    }
  }

  Future<void> getOrders() async {
    isLoading = true;
    notifyListeners();
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('orders').get();

      final allOrders = snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(
          doc.data(),
          doc.id,
        );
      }).toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

      _allOrdersCache = allOrders;

      final today = DateTime.now();
      final todayDateString = _dateKey(today);

      newOrders = allOrders.where((order) {
        final orderDate = DateTime.tryParse(order.createdDate);
        if (orderDate == null) return false;
        return _dateKey(orderDate) == todayDateString && !order.isCancelled;
      }).toList();

      cancelledOrders =
          allOrders.where((order) => order.isCancelled).toList();

      deliveredOrders =
          allOrders.where((order) => order.isDelivered && !order.isCancelled).toList();

      orders = allOrders.where((order) => !order.isCancelled).toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<OrderModel> baseListForPreset(OrderListPreset preset) {
    final all = _allOrdersCache ?? orders ?? [];
    switch (preset) {
      case OrderListPreset.newToday:
        return newOrders ?? [];
      case OrderListPreset.delivered:
        return deliveredOrders ?? [];
      case OrderListPreset.cancelled:
        return cancelledOrders ?? [];
      case OrderListPreset.all:
        return orders ?? all;
    }
  }

  List<OrderModel> get filteredOrders {
    var list = baseListForPreset(listPreset);

    switch (quickFilter) {
      case OrderQuickFilter.today:
        list = list.where(_isToday).toList();
        break;
      case OrderQuickFilter.thisWeek:
        list = list.where(_isThisWeek).toList();
        break;
      case OrderQuickFilter.cod:
        list = list.where((o) => !o.isPaid).toList();
        break;
      case OrderQuickFilter.paid:
        list = list.where((o) => o.isPaid).toList();
        break;
      case OrderQuickFilter.highValue:
        list = list.where((o) => o.getTotalAmount() >= 999).toList();
        break;
      case OrderQuickFilter.delivered:
        list = list.where((o) => o.isDelivered && !o.isCancelled).toList();
        break;
      case OrderQuickFilter.cancelled:
        list = list.where((o) => o.isCancelled).toList();
        break;
      case OrderQuickFilter.allOrders:
      case OrderQuickFilter.none:
        break;
    }

    if (searchQuery.isNotEmpty) {
      list = list.where((o) {
        final hay =
            '${o.id} ${o.customerName} ${o.phone} ${o.orderStatus} ${o.address}'
                .toLowerCase();
        return hay.contains(searchQuery);
      }).toList();
    }

    return list;
  }

  List<OrderModel> get pagedOrders {
    final list = filteredOrders;
    if (visibleCount >= list.length) return list;
    return list.sublist(0, visibleCount);
  }

  bool get hasMore => visibleCount < filteredOrders.length;

  OrderAnalyticsSnapshot get analytics {
    final all = _allOrdersCache ?? [];
    final pending = all
        .where((o) => !o.isCancelled && !o.isDelivered)
        .length;
    final delivered = all.where((o) => o.isDelivered && !o.isCancelled).length;
    final cancelled = all.where((o) => o.isCancelled).length;
    final revenue = all
        .where((o) => o.isDelivered && !o.isCancelled)
        .fold<double>(0, (s, o) => s + o.getTotalAmount());

    final now = DateTime.now();
    final thisWeek = all.where((o) => _inRange(o, now.subtract(const Duration(days: 7)), now));
    final prevWeek = all.where((o) => _inRange(
          o,
          now.subtract(const Duration(days: 14)),
          now.subtract(const Duration(days: 7)),
        ));

    final weekRev = thisWeek
        .where((o) => o.isDelivered)
        .fold<double>(0, (s, o) => s + o.getTotalAmount());
    final prevRev = prevWeek
        .where((o) => o.isDelivered)
        .fold<double>(0, (s, o) => s + o.getTotalAmount());

    return OrderAnalyticsSnapshot(
      totalOrders: all.length,
      pendingOrders: pending,
      deliveredOrders: delivered,
      cancelledOrders: cancelled,
      revenue: revenue,
      revenueTrendPct: _pctChange(prevRev, weekRev),
      ordersTrendPct: _pctChange(prevWeek.length.toDouble(), thisWeek.length.toDouble()),
    );
  }

  List<OrderChartPoint> ordersTrendLast7Days() {
    final all = _allOrdersCache ?? [];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(
        Duration(days: 6 - i),
      );
      final next = day.add(const Duration(days: 1));
      final count = all.where((o) => _inRange(o, day, next)).length;
      return OrderChartPoint(_shortDay(day), count.toDouble());
    });
  }

  List<OrderChartPoint> revenueTrendLast7Days() {
    final all = _allOrdersCache ?? [];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(
        Duration(days: 6 - i),
      );
      final next = day.add(const Duration(days: 1));
      final rev = all
          .where((o) => o.isDelivered && _inRange(o, day, next))
          .fold<double>(0, (s, o) => s + o.getTotalAmount());
      return OrderChartPoint(_shortDay(day), rev);
    });
  }

  List<OrderChartPoint> peakHoursToday() {
    final all = _allOrdersCache ?? [];
    final today = DateTime.now();
    final buckets = List<double>.filled(24, 0);
    for (final o in all) {
      final dt = DateTime.tryParse(o.createdDate);
      if (dt == null) continue;
      if (_dateKey(dt) != _dateKey(today)) continue;
      buckets[dt.hour]++;
    }
    return List.generate(
      24,
      (h) => OrderChartPoint('${h.toString().padLeft(2, '0')}h', buckets[h]),
    );
  }

  List<MapEntry<String, int>> statusBreakdown() {
    final all = _allOrdersCache ?? [];
    final map = <String, int>{};
    for (final o in all) {
      final label = OrderStatusUtils.styleForOrder(o).label;
      map[label] = (map[label] ?? 0) + 1;
    }
    return map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _shortDay(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]} ${d.day}';
  }

  static bool _isToday(OrderModel o) {
    final dt = DateTime.tryParse(o.createdDate);
    if (dt == null) return false;
    final now = DateTime.now();
    return _dateKey(dt) == _dateKey(now);
  }

  static bool _isThisWeek(OrderModel o) {
    final dt = DateTime.tryParse(o.createdDate);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.isAfter(now.subtract(const Duration(days: 7)));
  }

  static bool _inRange(OrderModel o, DateTime start, DateTime end) {
    final dt = DateTime.tryParse(o.createdDate);
    if (dt == null) return false;
    return !dt.isBefore(start) && dt.isBefore(end);
  }

  static double _pctChange(double prev, double current) {
    if (prev <= 0) return current > 0 ? 100 : 0;
    return ((current - prev) / prev) * 100;
  }
}
