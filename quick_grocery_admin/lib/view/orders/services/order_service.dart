import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/widgets/refund_stats_row.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_eta_utils.dart';
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
    required this.revenueToday,
    required this.revenueTrendPct,
    required this.ordersTrendPct,
    required this.avgDeliveryMinutes,
    required this.codPct,
    required this.onlinePaymentPct,
    required this.pendingDeliveryCount,
    required this.unassignedRiderCount,
    required this.delayedOrdersCount,
  });

  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double revenue;
  final double revenueToday;
  final double revenueTrendPct;
  final double ordersTrendPct;
  final double avgDeliveryMinutes;
  final double codPct;
  final double onlinePaymentPct;
  final int pendingDeliveryCount;
  final int unassignedRiderCount;
  final int delayedOrdersCount;
}

/// Live stats for the New Orders dispatch page.
class NewOrdersLiveStats {
  const NewOrdersLiveStats({
    required this.newToday,
    required this.pendingAssignment,
    required this.delayed,
    required this.ridersAvailable,
    required this.avgDispatchMinutes,
  });

  final int newToday;
  final int pendingAssignment;
  final int delayed;
  final int ridersAvailable;
  final String avgDispatchMinutes;
}

class OrderOperationalInsights {
  const OrderOperationalInsights({
    required this.peakOrderingHour,
    required this.avgDeliveryMinutes,
    required this.mostActiveArea,
    required this.topCategory,
    required this.pendingDeliveryCount,
    required this.riderUtilizationPct,
    required this.codRiskCount,
    required this.isPeakTraffic,
  });

  final String peakOrderingHour;
  final String avgDeliveryMinutes;
  final String mostActiveArea;
  final String topCategory;
  final int pendingDeliveryCount;
  final double riderUtilizationPct;
  final int codRiskCount;
  final bool isPeakTraffic;
}

class OrderService extends ChangeNotifier {
  CustomerModel? customer;
  VendorModel? vendor;
  AddressModel? address;
  List<OrderModel>? orders;

  bool isLoading = false;
  String searchQuery = '';
  OrderQuickFilter quickFilter = OrderQuickFilter.allOrders;
  OrderModulePage modulePage = OrderModulePage.manage;
  int pageSize = 15;
  int visibleCount = 15;

  final TextEditingController searchController = TextEditingController();

  List<OrderModel>? _allOrdersCache;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void setModulePage(OrderModulePage page) {
    modulePage = page;
    visibleCount = pageSize;
    if (page == OrderModulePage.refund) {
      quickFilter = OrderQuickFilter.allOrders;
    }
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

      orders = allOrders;
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cancelled orders for refund review (refund/dispute flagged first in UI sort).
  List<OrderModel> _refundOrders(List<OrderModel> all) {
    final cancelled = all.where((o) => o.isCancelled).toList();
    cancelled.sort((a, b) {
      final aFlag = _isRefundFlagged(a) ? 0 : 1;
      final bFlag = _isRefundFlagged(b) ? 0 : 1;
      if (aFlag != bFlag) return aFlag.compareTo(bFlag);
      return b.createdDate.compareTo(a.createdDate);
    });
    return cancelled;
  }

  static bool _isRefundFlagged(OrderModel o) {
    final s = o.orderStatus.toLowerCase();
    return s.contains('refund') || s.contains('dispute');
  }

  RefundStats get refundStats {
    final all = _allOrdersCache ?? [];
    final cancelled = all.where((o) => o.isCancelled).toList();
    final flagged = cancelled.where(_isRefundFlagged).length;
    return RefundStats(
      totalCancelled: cancelled.length,
      refundFlagged: flagged,
      pendingReview: cancelled.length - flagged,
      codRefunds: cancelled.where((o) => !o.isPaid).length,
    );
  }

  List<OrderModel> get ordersToday {
    final all = _allOrdersCache ?? [];
    final todayKey = _dateKey(DateTime.now());
    return all.where((o) {
      final dt = DateTime.tryParse(o.createdDate);
      return dt != null && _dateKey(dt) == todayKey && !o.isCancelled;
    }).toList();
  }

  /// Active today orders needing a rider.
  List<OrderModel> get dispatchQueue {
    return ordersToday
        .where((o) => !o.isDelivered && o.deliveryBoyId.isEmpty)
        .toList();
  }

  NewOrdersLiveStats get newOrdersLiveStats {
    final today = ordersToday;
    final pending = today.where((o) => !o.isDelivered).length;
    final unassigned = dispatchQueue.length;
    final delayed = today.where(OrderEtaUtils.isDelayed).length;
    return NewOrdersLiveStats(
      newToday: today.length,
      pendingAssignment: unassigned,
      delayed: delayed,
      ridersAvailable: 0,
      avgDispatchMinutes:
          '${_avgDeliveryMinutes(_allOrdersCache ?? []).toStringAsFixed(0)}m',
    );
  }

  List<OrderModel> get filteredOrders {
    var list = List<OrderModel>.from(_allOrdersCache ?? orders ?? []);

    if (modulePage == OrderModulePage.refund) {
      list = _refundOrders(list);
    } else if (modulePage == OrderModulePage.newOrders) {
      list = ordersToday.where((o) => !o.isDelivered).toList();
    } else {
      list = _applyQuickFilter(list, quickFilter);
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
    final active = all.where((o) => !o.isCancelled && !o.isDelivered);
    final pending = active.length;
    final delivered = all.where((o) => o.isDelivered && !o.isCancelled).length;
    final cancelled = all.where((o) => o.isCancelled).length;
    final revenue = all
        .where((o) => o.isDelivered && !o.isCancelled)
        .fold<double>(0, (s, o) => s + o.getTotalAmount());

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final revenueToday = all
        .where((o) {
          final dt = DateTime.tryParse(o.createdDate);
          return dt != null &&
              _dateKey(dt) == todayKey &&
              o.isDelivered &&
              !o.isCancelled;
        })
        .fold<double>(0, (s, o) => s + o.getTotalAmount());

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

    final paidCount = all.where((o) => o.isPaid).length;
    final codPct = all.isEmpty ? 0.0 : ((all.length - paidCount) / all.length) * 100;
    final onlinePct = all.isEmpty ? 0.0 : (paidCount / all.length) * 100;

    final unassigned = active.where((o) => o.deliveryBoyId.isEmpty).length;
    final delayed = active.where(OrderEtaUtils.isDelayed).length;

    return OrderAnalyticsSnapshot(
      totalOrders: all.length,
      pendingOrders: pending,
      deliveredOrders: delivered,
      cancelledOrders: cancelled,
      revenue: revenue,
      revenueToday: revenueToday,
      revenueTrendPct: _pctChange(prevRev, weekRev),
      ordersTrendPct: _pctChange(prevWeek.length.toDouble(), thisWeek.length.toDouble()),
      avgDeliveryMinutes: _avgDeliveryMinutes(all),
      codPct: codPct,
      onlinePaymentPct: onlinePct,
      pendingDeliveryCount: pending,
      unassignedRiderCount: unassigned,
      delayedOrdersCount: delayed,
    );
  }

  OrderOperationalInsights get operationalInsights {
    final all = _allOrdersCache ?? [];
    final peak = peakHoursToday();
    final peakEntry = peak.isEmpty
        ? null
        : peak.reduce((a, b) => a.value >= b.value ? a : b);

    final areas = <String, int>{};
    for (final o in all) {
      final key = o.address.trim().isEmpty ? 'Unknown' : o.address.split(',').first.trim();
      areas[key] = (areas[key] ?? 0) + 1;
    }
    final topArea = areas.entries.isEmpty
        ? '—'
        : areas.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final categories = <String, int>{};
    for (final o in all) {
      for (final p in o.products) {
        final cat = p.category.trim().isEmpty ? 'General' : p.category;
        categories[cat] = (categories[cat] ?? 0) + p.itemCount;
      }
    }
    final topCat = categories.entries.isEmpty
        ? '—'
        : categories.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final active = all.where((o) => !o.isCancelled && !o.isDelivered).toList();
    final assigned = active.where((o) => o.deliveryBoyId.isNotEmpty).length;
    final utilization = active.isEmpty ? 0.0 : (assigned / active.length) * 100;

    final codRisk = all
        .where((o) => !o.isPaid && !o.isDelivered && !o.isCancelled && o.getTotalAmount() >= 1500)
        .length;

    final peakHourLabel = peakEntry == null || peakEntry.value <= 0
        ? '—'
        : peakEntry.label;

    return OrderOperationalInsights(
      peakOrderingHour: peakHourLabel,
      avgDeliveryMinutes: '${_avgDeliveryMinutes(all).toStringAsFixed(0)} min',
      mostActiveArea: topArea,
      topCategory: topCat,
      pendingDeliveryCount: active.length,
      riderUtilizationPct: utilization,
      codRiskCount: codRisk,
      isPeakTraffic: (peakEntry?.value ?? 0) >= 3,
    );
  }

  List<OrderModel> get recentOrdersForOverview {
    final all = _allOrdersCache ?? [];
    return all.take(8).toList();
  }

  static double _avgDeliveryMinutes(List<OrderModel> all) {
    final durations = <double>[];
    for (final o in all) {
      if (!o.isDelivered) continue;
      final start = DateTime.tryParse(o.createdDate);
      final end = DateTime.tryParse(o.orderDeliveredTime);
      if (start == null || end == null) continue;
      final mins = end.difference(start).inMinutes;
      if (mins > 0 && mins < 24 * 60) durations.add(mins.toDouble());
    }
    if (durations.isEmpty) return 0;
    return durations.reduce((a, b) => a + b) / durations.length;
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

  static List<OrderModel> _applyQuickFilter(
    List<OrderModel> list,
    OrderQuickFilter filter,
  ) {
    switch (filter) {
      case OrderQuickFilter.allOrders:
        return list;
      case OrderQuickFilter.pending:
        return list
            .where(
              (o) =>
                  !o.isCancelled &&
                  !o.isDelivered &&
                  (o.orderStatus.isEmpty ||
                      o.orderStatus.toLowerCase().contains('pending')),
            )
            .toList();
      case OrderQuickFilter.assigned:
        return list
            .where(
              (o) =>
                  !o.isCancelled &&
                  !o.isDelivered &&
                  o.deliveryBoyId.isNotEmpty,
            )
            .toList();
      case OrderQuickFilter.waiting:
        return list
            .where(
              (o) =>
                  !o.isCancelled &&
                  !o.isDelivered &&
                  (o.orderStatus.toLowerCase().contains('wait') ||
                      o.orderStatus.toLowerCase().contains('confirm')),
            )
            .toList();
      case OrderQuickFilter.delivered:
        return list.where((o) => o.isDelivered && !o.isCancelled).toList();
      case OrderQuickFilter.cancelled:
        return list.where((o) => o.isCancelled).toList();
      case OrderQuickFilter.cod:
        return list.where((o) => !o.isPaid).toList();
      case OrderQuickFilter.online:
        return list.where((o) => o.isPaid).toList();
      case OrderQuickFilter.highValue:
        return list.where((o) => o.getTotalAmount() >= 999).toList();
      case OrderQuickFilter.scheduled:
        return list
            .where((o) => o.deliveryType.toLowerCase().contains('schedule'))
            .toList();
    }
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
