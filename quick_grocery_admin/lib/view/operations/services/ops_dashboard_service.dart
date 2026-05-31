import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_order_queue_manager.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_analytics_service.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';

/// Live ops dashboard: single orders stream + auxiliary collections.
class OpsDashboardService extends ChangeNotifier {
  OpsDashboardService() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listen();
      } else {
        _stopListening();
      }
    });
  }

  StreamSubscription<User?>? _authSub;

  final _db = FirebaseFirestore.instance;

  bool isLoadingOrders = true;
  String? ordersError;

  int pendingOrders = 0;
  int pendingAssignment = 0;
  int assignedActiveOrders = 0;
  int deliveredToday = 0;
  int failedDeliveriesToday = 0;
  int onlineRiders = 0;
  int lowStockCount = 0;
  int activeCustomersToday = 0;

  OpsRevenueSnapshot revenue = const OpsRevenueSnapshot();
  List<OpsLiveOrder> liveOrders = [];
  List<OpsActivityEntry> recentActivities = [];

  final Map<String, String> _vendorNames = {};
  final Map<String, String> _riderNames = {};
  final Set<String> _knownActiveOrderIds = {};
  List<Map<String, dynamic>> _orderDocs = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ridersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _vendorsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _stockSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitySub;

  Timer? _notifyDebounce;
  bool _disposed = false;

  void _stopListening() {
    _ordersSub?.cancel();
    _ordersSub = null;
    _ridersSub?.cancel();
    _ridersSub = null;
    _vendorsSub?.cancel();
    _vendorsSub = null;
    _stockSub?.cancel();
    _stockSub = null;
    _activitySub?.cancel();
    _activitySub = null;
    isLoadingOrders = false;
    _scheduleNotify();
  }

  void retryOrdersStream() {
    ordersError = null;
    isLoadingOrders = true;
    _listen();
    _scheduleNotify();
  }

  void _listen() {
    _ordersSub?.cancel();
    _ridersSub?.cancel();
    _vendorsSub?.cancel();
    _stockSub?.cancel();
    _activitySub?.cancel();
    isLoadingOrders = true;

    _ordersSub = _db.collection('orders').snapshots().listen(
      (snap) {
        _orderDocs = snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        _recomputeOrders();
        isLoadingOrders = false;
        ordersError = null;
        _scheduleNotify();
      },
      onError: (Object e, StackTrace st) {
        if (kDebugMode) debugPrint('OpsDashboardService orders: $e\n$st');
        isLoadingOrders = false;
        ordersError = e.toString();
        _scheduleNotify();
      },
    );

    _ridersSub = _db.collection('delivery_boys').snapshots().listen(
      (snap) {
        _riderNames
          ..clear()
          ..addEntries(
            snap.docs.map(
              (d) => MapEntry(
                d.id,
                (d.data()['name'] ?? d.data()['fullName'] ?? 'Rider')
                    .toString(),
              ),
            ),
          );
        onlineRiders =
            snap.docs.where((d) => d.data()['isOnline'] == true).length;
        _recomputeOrders();
        _scheduleNotify();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('OpsDashboardService riders: $e');
      },
    );

    _vendorsSub = _db.collection('vendors').limit(500).snapshots().listen(
      (snap) {
        _vendorNames
          ..clear()
          ..addEntries(
            snap.docs.map((d) {
              final data = d.data();
              final name = (data['shopName'] ??
                      data['shop_name'] ??
                      data['name'] ??
                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                  .toString()
                  .trim();
              return MapEntry(d.id, name.isEmpty ? d.id : name);
            }),
          );
        _recomputeOrders();
        _scheduleNotify();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('OpsDashboardService vendors: $e');
      },
    );

    _stockSub = _db
        .collection('products')
        .where('stockStatus', whereIn: ['low_stock', 'out_of_stock'])
        .limit(100)
        .snapshots()
        .listen(
      (snap) {
        lowStockCount = snap.size;
        _scheduleNotify();
      },
      onError: (_) {
        lowStockCount = 0;
        _scheduleNotify();
      },
    );

    _activitySub = _db
        .collection('activity_logs')
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots()
        .listen(
      (snap) {
        recentActivities = snap.docs
            .map((d) => OpsActivityEntry.fromMap({...d.data(), 'id': d.id}))
            .toList();
        _scheduleNotify();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('OpsDashboardService activity: $e');
        recentActivities = [];
        _scheduleNotify();
      },
    );
  }

  void _recomputeOrders() {
    final metrics = AdminAnalyticsService.fromOrderMaps(_orderDocs);
    pendingOrders = metrics.pendingOrders;
    pendingAssignment = metrics.pendingAssignment;
    assignedActiveOrders = metrics.assignedActiveOrders;
    deliveredToday = metrics.deliveredToday;
    failedDeliveriesToday = metrics.failedDeliveriesToday;
    revenue = metrics.revenue;

    final todayStart = OpsFirestoreHelpers.startOfLocalDay();
    final customersToday = <String>{};
    for (final d in _orderDocs) {
      final created = OpsFirestoreHelpers.createdAt(d);
      if (OpsFirestoreHelpers.isOnLocalDay(created, todayStart) &&
          !OpsFirestoreHelpers.isCancelled(d)) {
        final uid = (d['uuid'] ?? d['customerId'] ?? '').toString();
        if (uid.isNotEmpty) customersToday.add(uid);
      }
    }
    activeCustomersToday = customersToday.length;

    final previousIds = Set<String>.from(_knownActiveOrderIds);
    liveOrders = OpsOrderQueueManager.buildActiveQueue(
      orders: _orderDocs,
      vendorNames: _vendorNames,
      riderNames: _riderNames,
      previousActiveIds: previousIds,
    );

    _knownActiveOrderIds
      ..clear()
      ..addAll(
        _orderDocs.where(OpsFirestoreHelpers.isActive).map((d) => d['id'].toString()),
      );
  }

  void _scheduleNotify() {
    if (_disposed) return;
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 80), () {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _notifyDebounce?.cancel();
    _ordersSub?.cancel();
    _ridersSub?.cancel();
    _vendorsSub?.cancel();
    _stockSub?.cancel();
    _activitySub?.cancel();
    super.dispose();
  }
}
