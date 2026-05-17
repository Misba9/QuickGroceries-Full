import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarningsSnapshot {
  const EarningsSnapshot({
    required this.today,
    required this.week,
    required this.month,
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.pending,
    required this.incentives,
    required this.avgRating,
    required this.acceptanceRate,
  });

  final double today;
  final double week;
  final double month;
  final double total;
  final int completed;
  final int cancelled;
  final int pending;
  final double incentives;
  final double avgRating;
  final double acceptanceRate;

  static const empty = EarningsSnapshot(
    today: 0,
    week: 0,
    month: 0,
    total: 0,
    completed: 0,
    cancelled: 0,
    pending: 0,
    incentives: 0,
    avgRating: 0,
    acceptanceRate: 0,
  );
}

class DriverEarningsService {
  DriverEarningsService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<String> _riderId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('deliveryBoyId') ?? '';
  }

  Future<EarningsSnapshot> compute({List<OrderModel>? cachedOrders}) async {
    final id = await _riderId();
    if (id.isEmpty) return EarningsSnapshot.empty;

    final orders = cachedOrders ?? await _fetchRiderOrders(id);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    double today = 0, week = 0, month = 0, total = 0, incentives = 0;
    int completed = 0, cancelled = 0, pending = 0;
    double ratingSum = 0;
    int rated = 0;
    int accepted = 0;
    int offered = 0;

    for (final o in orders) {
      final deliveredAt = _parseDate(o.orderDeliveredTime);
      final earning = _orderEarning(o);

      if (o.isCancelled) {
        cancelled++;
        continue;
      }

      if (o.deliveryBoyId.isEmpty &&
          !o.isDelivered &&
          o.orderStatus.toLowerCase().contains('confirm')) {
        pending++;
        offered++;
        continue;
      }

      if (o.deliveryBoyId == id) {
        accepted++;
        if (o.isDelivered) {
          completed++;
          total += earning;
          if (deliveredAt != null) {
            if (!deliveredAt.isBefore(startOfDay)) today += earning;
            if (!deliveredAt.isBefore(startOfWeek)) week += earning;
            if (!deliveredAt.isBefore(startOfMonth)) month += earning;
          }
          if (o.isRated && o.rating > 0) {
            ratingSum += o.rating;
            rated++;
          }
        }
      }
      offered++;
    }

    final acceptance = offered > 0 ? (accepted / offered) * 100 : 100.0;

    return EarningsSnapshot(
      today: today,
      week: week,
      month: month,
      total: total,
      completed: completed,
      cancelled: cancelled,
      pending: pending,
      incentives: incentives,
      avgRating: rated > 0 ? ratingSum / rated : 0,
      acceptanceRate: acceptance,
    );
  }

  Future<void> syncStatsToProfile(EarningsSnapshot snap) async {
    final id = await _riderId();
    if (id.isEmpty) return;
    await _db.collection('delivery_boys').doc(id).set({
      'total_earnings': snap.total,
      'completed_orders': snap.completed,
      'rejected_orders': snap.cancelled,
      'acceptance_rate': snap.acceptanceRate,
      'driver_rating': snap.avgRating,
    }, SetOptions(merge: true));
  }

  Future<List<OrderModel>> _fetchRiderOrders(String id) async {
    final snap = await _db.collection('orders').get();
    return snap.docs
        .map((d) => OrderModel.fromFirestore(d.data(), d.id))
        .where((o) => o.deliveryBoyId == id || o.deliveryBoyId.isEmpty)
        .toList();
  }

  double _orderEarning(OrderModel o) {
    if (o.deliveryCharge > 0) return o.deliveryCharge.toDouble();
    return o.products.fold<double>(
      0,
      (sum, p) => sum + ((p.price ?? 0) * (p.itemCount ?? 0)) * 0.05,
    );
  }

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
