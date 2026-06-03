import 'dart:async';

import 'package:quick_grocery_admin/core/order_lifecycle.dart';
import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/widgets/refund_stats_row.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_analytics_service.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_eta_utils.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_status_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  OrderService() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startRealtimeOrders();
      } else {
        _stopRealtimeOrders();
      }
    });
  }

  StreamSubscription<User?>? _authSub;

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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;

  void _stopRealtimeOrders() {
    _ordersSub?.cancel();
    _ordersSub = null;
    orders = null;
    _allOrdersCache = null;
    isLoading = false;
    notifyListeners();
  }

  void _startRealtimeOrders() {
    if (_ordersSub != null) return;
    isLoading = true;
    _ordersSub = FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .listen(
      (snapshot) {
        final allOrders = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
            .toList()
          ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
        _allOrdersCache = allOrders;
        orders = allOrders;
        isLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('OrderService realtime: $e');
        isLoading = false;
        notifyListeners();
        if (FirebaseAuth.instance.currentUser != null) {
          Future<void>.delayed(const Duration(seconds: 3), _startRealtimeOrders);
        }
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _ordersSub?.cancel();
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
        'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.cancelled),
        'status': OrderLifecycle.cancelled,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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
        'delivery_boy_id': deliveryBoyId,
        'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.riderAssigned),
        'status': OrderLifecycle.riderAssigned,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    if (_ordersSub != null) return;
    _startRealtimeOrders();
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

  /// Orders waiting for rider assignment (vendor accepted → ready for pickup).
  List<OrderModel> get unassignedOrders => dispatchQueue;

  /// Active today orders needing a rider (vendor accepted+, no rider yet).
  List<OrderModel> get dispatchQueue {
    return ordersToday.where((o) {
      if (o.isDelivered || o.isCancelled) return false;
      if (o.deliveryBoyId.isNotEmpty) return false;
      final status = OrderLifecycle.resolveFromOrder(
        isCancelled: o.isCancelled,
        isDelivered: o.isDelivered,
        modernStatus: o.modernStatus,
        legacyStatus: o.orderStatus,
      );
      return status == OrderLifecycle.orderPlaced;
    }).toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
  }

  NewOrdersLiveStats get newOrdersLiveStats {
    final today = ordersToday;
    final unassigned = dispatchQueue.length;
    final delayed = today.where(OrderEtaUtils.isDelayed).length;
    final avgMin = (_allOrdersCache ?? []).isEmpty
        ? 0.0
        : AdminAnalyticsService.fromOrderModels(_allOrdersCache!)
            .orderAnalytics
            .avgDeliveryMinutes;
    return NewOrdersLiveStats(
      newToday: today.length,
      pendingAssignment: unassigned,
      delayed: delayed,
      ridersAvailable: 0,
      avgDispatchMinutes: '${avgMin.toStringAsFixed(0)}m',
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
    if (all.isEmpty) {
      return const OrderAnalyticsSnapshot(
        totalOrders: 0,
        pendingOrders: 0,
        deliveredOrders: 0,
        cancelledOrders: 0,
        revenue: 0,
        revenueToday: 0,
        revenueTrendPct: 0,
        ordersTrendPct: 0,
        avgDeliveryMinutes: 0,
        codPct: 0,
        onlinePaymentPct: 0,
        pendingDeliveryCount: 0,
        unassignedRiderCount: 0,
        delayedOrdersCount: 0,
      );
    }
    return AdminAnalyticsService.fromOrderModels(all).orderAnalytics;
  }

  OrderOperationalInsights get operationalInsights {
    final all = _allOrdersCache ?? [];
    if (all.isEmpty) {
      return const OrderOperationalInsights(
        peakOrderingHour: '—',
        avgDeliveryMinutes: '0 min',
        mostActiveArea: '—',
        topCategory: '—',
        pendingDeliveryCount: 0,
        riderUtilizationPct: 0,
        codRiskCount: 0,
        isPeakTraffic: false,
      );
    }
    return AdminAnalyticsService.fromOrderModels(all).operationalInsights;
  }

  List<OrderChartPoint> ordersTrendLast7Days() {
    final all = _allOrdersCache ?? [];
    if (all.isEmpty) return const [];
    return AdminAnalyticsService.fromOrderModels(all)
        .revenue
        .ordersTrend7d
        .map((p) => OrderChartPoint(p.label, p.value))
        .toList();
  }

  List<OrderChartPoint> revenueTrendLast7Days() {
    final all = _allOrdersCache ?? [];
    if (all.isEmpty) return const [];
    return AdminAnalyticsService.fromOrderModels(all)
        .revenue
        .revenueTrend7d
        .map((p) => OrderChartPoint(p.label, p.value))
        .toList();
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

  static List<OrderModel> _applyQuickFilter(
    List<OrderModel> list,
    OrderQuickFilter filter,
  ) {
    String statusOf(OrderModel o) => OrderLifecycle.resolveFromOrder(
          isCancelled: o.isCancelled,
          isDelivered: o.isDelivered,
          modernStatus: o.modernStatus,
          legacyStatus: o.orderStatus,
        );

    switch (filter) {
      case OrderQuickFilter.allOrders:
        return list;
      case OrderQuickFilter.pending:
        return list.where((o) {
          if (o.isCancelled || o.isDelivered) return false;
          return statusOf(o) == OrderLifecycle.orderPlaced;
        }).toList();
      case OrderQuickFilter.assigned:
        return list.where((o) {
          if (o.isCancelled || o.isDelivered) return false;
          final s = statusOf(o);
          return s == OrderLifecycle.deliveryAssigned ||
              (o.deliveryBoyId.isNotEmpty &&
                  s != OrderLifecycle.outForDelivery);
        }).toList();
      case OrderQuickFilter.waiting:
        return list.where((o) {
          if (o.isCancelled || o.isDelivered) return false;
          final s = statusOf(o);
          return s == OrderLifecycle.orderPlaced && o.deliveryBoyId.isEmpty;
        }).toList();
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

}
