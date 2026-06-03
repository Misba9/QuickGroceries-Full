import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarningsSnapshot {
  const EarningsSnapshot({
    required this.today,
    required this.week,
    required this.month,
    required this.total,
    required this.todayTips,
    required this.weekTips,
    required this.monthTips,
    required this.lifetimeTips,
    required this.avgTipPerOrder,
    required this.completed,
    required this.cancelled,
    required this.riderCancellations,
    required this.pendingOffers,
    required this.inProgress,
    required this.incentives,
    required this.avgRating,
    required this.acceptanceRate,
  });

  final double today;
  final double week;
  final double month;
  final double total;
  final double todayTips;
  final double weekTips;
  final double monthTips;
  final double lifetimeTips;
  final double avgTipPerOrder;
  final int completed;
  final int cancelled;
  final int riderCancellations;
  final int pendingOffers;
  final int inProgress;
  final double incentives;
  final double avgRating;
  final double acceptanceRate;

  static const empty = EarningsSnapshot(
    today: 0,
    week: 0,
    month: 0,
    total: 0,
    todayTips: 0,
    weekTips: 0,
    monthTips: 0,
    lifetimeTips: 0,
    avgTipPerOrder: 0,
    completed: 0,
    cancelled: 0,
    riderCancellations: 0,
    pendingOffers: 0,
    inProgress: 0,
    incentives: 0,
    avgRating: 0,
    acceptanceRate: 0,
  );
}

class DriverEarningsService {
  DriverEarningsService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

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
    final last7Days = startOfDay.subtract(const Duration(days: 6));
    final startOfMonth = DateTime(now.year, now.month, 1);

    double today = 0, week = 0, month = 0, total = 0;
    double todayTips = 0, weekTips = 0, monthTips = 0, lifetimeTips = 0;
    int completed = 0;
    int tippedOrders = 0;
    int cancelled = 0;
    int riderCancellations = 0;
    int pendingOffers = 0;
    int inProgress = 0;
    int assigned = 0;
    int accepted = 0;
    double ratingSum = 0;
    int rated = 0;

    for (final o in orders) {
      if (o.deliveryBoyId != id && o.deliveryBoyId.isNotEmpty) continue;

      final status = OrderLifecycle.resolveStatus({
        'status': o.modernStatus,
        'order_status': o.orderStatus,
        'isCancelled': o.isCancelled,
        'isDelivered': o.isDelivered,
      });

      // Rider backed out — tracked via rejection fields on reassigned orders.
      if (o.deliveryBoyId.isEmpty) continue;

      if (OrderLifecycle.isCancellationStatus(status) ||
          (o.isCancelled && status != OrderLifecycle.cancelledByVendor)) {
        if (status == OrderLifecycle.cancelledByCustomer ||
            status == OrderLifecycle.cancelledByVendor ||
            status == OrderLifecycle.cancelled) {
          cancelled++;
        }
        continue;
      }

      if (OrderLifecycle.needsRiderAcceptance(status)) {
        pendingOffers++;
        assigned++;
        continue;
      }

      assigned++;
      accepted++;

      if (OrderLifecycle.isInTransit(status)) {
        inProgress++;
      }

      if (o.isDelivered || status == OrderLifecycle.delivered) {
        completed++;
        final deliveredAt = _parseDate(o.orderDeliveredTime);
        final earning = _orderEarning(o);
        final tip = o.tipEarning;
        total += earning;
        lifetimeTips += tip;
        if (tip > 0) tippedOrders++;
        if (deliveredAt != null) {
          if (!deliveredAt.isBefore(startOfDay)) {
            today += earning;
            todayTips += tip;
          }
          if (!deliveredAt.isBefore(last7Days)) {
            week += earning;
            weekTips += tip;
          }
          if (!deliveredAt.isBefore(startOfMonth)) {
            month += earning;
            monthTips += tip;
          }
        }
        if (o.isRated && o.rating > 0) {
          ratingSum += o.rating;
          rated++;
        }
      }
    }

    // Rider-initiated cancellations (order returned to queue).
    final rejectSnap = await _db
        .collection('orders')
        .where('rider_rejected_by', isEqualTo: id)
        .get();
    riderCancellations = rejectSnap.docs.length;

    final acceptance = assigned > 0 ? (accepted / assigned) * 100 : 100.0;

    final avgTip =
        tippedOrders > 0 ? lifetimeTips / tippedOrders : 0.0;

    return EarningsSnapshot(
      today: today,
      week: week,
      month: month,
      total: total,
      todayTips: todayTips,
      weekTips: weekTips,
      monthTips: monthTips,
      lifetimeTips: lifetimeTips,
      avgTipPerOrder: avgTip,
      completed: completed,
      cancelled: cancelled,
      riderCancellations: riderCancellations,
      pendingOffers: pendingOffers,
      inProgress: inProgress,
      incentives: 0,
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
      'rejected_orders': snap.riderCancellations,
      'cancelled_orders': snap.cancelled,
      'acceptance_rate': snap.acceptanceRate,
      'driver_rating': snap.avgRating,
      'stats_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<OrderModel>> _fetchRiderOrders(String id) async {
    final snap = await _db
        .collection('orders')
        .where('deliveryBoyId', isEqualTo: id)
        .get();
    return snap.docs
        .map((d) => OrderModel.fromFirestore(d.data(), d.id))
        .toList();
  }

  double _orderEarning(OrderModel o) => o.deliveryFeeEarning + o.tipEarning;

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
