import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Live ops counters for the real-time control tower (Firestore streams).
class OpsDashboardService extends ChangeNotifier {
  OpsDashboardService() {
    _listen();
  }

  final _db = FirebaseFirestore.instance;

  int pendingOrders = 0;
  int deliveredToday = 0;
  int onlineRiders = 0;
  int lowStockCount = 0;
  int activeCustomersToday = 0;
  double revenueToday = 0;
  List<Map<String, dynamic>> liveOrders = [];
  List<Map<String, dynamic>> recentActivities = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ridersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _stockSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitySub;

  void _listen() {
    final startOfDay = DateTime.now();
    final dayStart = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);

    _ordersSub = _db.collection('orders').snapshots().listen((snap) {
      pendingOrders = 0;
      deliveredToday = 0;
      revenueToday = 0;
      final orders = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final d = {...doc.data(), 'id': doc.id};
        final status =
            (d['order_status'] ?? d['status'] ?? '').toString().toLowerCase();
        final cancelled = d['isCancelled'] == true;
        if (!cancelled &&
            !status.contains('delivered') &&
            !status.contains('cancel')) {
          pendingOrders++;
          orders.add(d);
        }
        final created = _parseDate(d['createdAt'] ?? d['created_date']);
        if (created != null && created.isAfter(dayStart)) {
          if (status.contains('delivered')) deliveredToday++;
          final bill = d['bill'];
          if (bill is Map && bill['total'] != null) {
            revenueToday += (bill['total'] as num).toDouble();
          }
        }
      }
      orders.sort((a, b) {
        final ta = _parseDate(a['createdAt'] ?? a['created_date']);
        final tb = _parseDate(b['createdAt'] ?? b['created_date']);
        return (tb ?? DateTime(0)).compareTo(ta ?? DateTime(0));
      });
      liveOrders = orders.take(12).toList();
      notifyListeners();
    });

    _ridersSub = _db.collection('delivery_boys').snapshots().listen((snap) {
      onlineRiders = snap.docs.where((d) => d.data()['isOnline'] == true).length;
      notifyListeners();
    });

    _stockSub = _db
        .collection('products')
        .where('stockStatus', whereIn: ['low_stock', 'out_of_stock'])
        .limit(100)
        .snapshots()
        .listen((snap) {
      lowStockCount = snap.size;
      notifyListeners();
    }, onError: (_) {
      lowStockCount = 0;
      notifyListeners();
    });

    _activitySub = _db
        .collection('activity_logs')
        .orderBy('createdAt', descending: true)
        .limit(15)
        .snapshots()
        .listen((snap) {
      recentActivities = snap.docs
          .map((d) => {...d.data(), 'id': d.id})
          .toList();
      notifyListeners();
    });
  }

  DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _ridersSub?.cancel();
    _stockSub?.cancel();
    _activitySub?.cancel();
    super.dispose();
  }
}
