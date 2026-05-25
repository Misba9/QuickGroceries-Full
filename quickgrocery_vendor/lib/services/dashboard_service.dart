import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../utils/vendor_order_utils.dart';
import 'order_service.dart';

class DashboardStats {
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final int totalProducts;
  final int activeProducts;
  final double totalRevenue;
  final double todayRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;

  const DashboardStats({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.totalProducts,
    required this.activeProducts,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
  });

  static const empty = DashboardStats(
    totalOrders: 0,
    activeOrders: 0,
    completedOrders: 0,
    pendingOrders: 0,
    cancelledOrders: 0,
    totalProducts: 0,
    activeProducts: 0,
    totalRevenue: 0,
    todayRevenue: 0,
    weeklyRevenue: 0,
    monthlyRevenue: 0,
  );
}

class DashboardService {
  DashboardService({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrderService _orderService;

  StreamSubscription<List<OrderModel>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSub;
  StreamController<DashboardStats>? _statsController;
  String? _watchingVendorId;

  List<OrderModel> _orders = [];
  int _activeProducts = 0;
  int _totalProducts = 0;

  /// Real-time dashboard stats (orders + active product counts).
  Stream<DashboardStats> watchVendorStats(String vendorId) {
    if (_watchingVendorId == vendorId && _statsController != null) {
      return _statsController!.stream;
    }
    stopWatching();
    _watchingVendorId = vendorId;
    _statsController = StreamController<DashboardStats>.broadcast();

    void emit() {
      if (_statsController == null || _statsController!.isClosed) return;
      _statsController!.add(
        _computeStats(vendorId, _orders, _activeProducts, _totalProducts),
      );
    }

    _ordersSub = _orderService.watchVendorOrders(vendorId).listen(
      (orders) {
        _orders = orders;
        emit();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('[DashboardService] orders stream: $e');
      },
    );

    _productsSub = _firestore
        .collection('products')
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()
        .listen(
      (snap) {
        _totalProducts = snap.docs.length;
        _activeProducts = snap.docs
            .where((d) => d.data()['is_active'] != false)
            .length;
        emit();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('[DashboardService] products stream: $e');
      },
    );

    return _statsController!.stream;
  }

  void stopWatching() {
    _ordersSub?.cancel();
    _productsSub?.cancel();
    _ordersSub = null;
    _productsSub = null;
    _statsController?.close();
    _statsController = null;
    _watchingVendorId = null;
    _orders = [];
    _activeProducts = 0;
    _totalProducts = 0;
  }

  Future<DashboardStats> getVendorStats(String vendorId) async {
    final orders = await _orderService.fetchVendorOrdersOnce(vendorId);
    final snap = await _firestore
        .collection('products')
        .where('vendor_id', isEqualTo: vendorId)
        .get();
    final active =
        snap.docs.where((d) => d.data()['is_active'] != false).length;
    return _computeStats(vendorId, orders, active, snap.docs.length);
  }

  DashboardStats _computeStats(
    String vendorId,
    List<OrderModel> vendorOrders,
    int activeProducts,
    int totalProducts,
  ) {
    var activeOrders = 0;
    var completedOrders = 0;
    var pendingOrders = 0;
    var cancelledOrders = 0;
    var totalRevenue = 0.0;
    var todayRevenue = 0.0;
    var weeklyRevenue = 0.0;
    var monthlyRevenue = 0.0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    for (final order in vendorOrders) {
      if (VendorOrderUtils.isCancelled(order)) {
        cancelledOrders++;
        continue;
      }
      if (VendorOrderUtils.isCompleted(order)) {
        completedOrders++;
      } else if (VendorOrderUtils.isPending(order)) {
        pendingOrders++;
        activeOrders++;
      } else {
        activeOrders++;
      }

      if (!VendorOrderUtils.countsForRevenue(order)) continue;
      final amount = VendorOrderUtils.vendorRevenueFromOrder(order, vendorId);
      totalRevenue += amount;
      final created = VendorOrderUtils.parseCreatedDate(order);
      if (created == null) continue;
      if (!created.isBefore(todayStart)) todayRevenue += amount;
      if (!created.isBefore(weekStart)) weeklyRevenue += amount;
      if (!created.isBefore(monthStart)) monthlyRevenue += amount;
    }

    return DashboardStats(
      totalOrders: vendorOrders.length,
      activeOrders: activeOrders,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      cancelledOrders: cancelledOrders,
      totalProducts: totalProducts,
      activeProducts: activeProducts,
      totalRevenue: totalRevenue,
      todayRevenue: todayRevenue,
      weeklyRevenue: weeklyRevenue,
      monthlyRevenue: monthlyRevenue,
    );
  }
}
