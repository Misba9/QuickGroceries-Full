import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/core/analytics/admin_date_ranges.dart';
import 'package:quick_grocery_admin/core/analytics/admin_order_record.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';

/// Single source of truth for admin revenue, counts, and operational insights.
class AdminAnalyticsResult {
  const AdminAnalyticsResult({
    required this.revenue,
    required this.pendingOrders,
    required this.pendingAssignment,
    required this.assignedActiveOrders,
    required this.deliveredToday,
    required this.failedDeliveriesToday,
    required this.cancelledToday,
    required this.orderAnalytics,
    required this.operationalInsights,
  });

  final OpsRevenueSnapshot revenue;
  final int pendingOrders;
  final int pendingAssignment;
  final int assignedActiveOrders;
  final int deliveredToday;
  final int failedDeliveriesToday;
  final int cancelledToday;
  final OrderAnalyticsSnapshot orderAnalytics;
  final OrderOperationalInsights operationalInsights;
}

abstract final class AdminAnalyticsEngine {
  static const slaMinutes = 45;

  static AdminAnalyticsResult compute(List<AdminOrderRecord> orders) {
    final now = AdminDateRanges.nowLocal;
    final todayStart = AdminDateRanges.todayStart;
    final yesterdayStart = AdminDateRanges.yesterdayStart;
    final yesterdayEnd = AdminDateRanges.yesterdayEndExclusive;
    final weekStart = AdminDateRanges.weekStart;
    final weekEnd = AdminDateRanges.weekEndExclusive;
    final monthStart = AdminDateRanges.monthStart;
    final monthEnd = AdminDateRanges.monthEndExclusive;

    var revenueToday = 0.0;
    var revenueYesterday = 0.0;
    var revenueWeekly = 0.0;
    var revenueMonthly = 0.0;
    var revenueAllTime = 0.0;

    var pending = 0;
    var unassigned = 0;
    var assigned = 0;
    var deliveredToday = 0;
    var failedToday = 0;
    var cancelledToday = 0;
    var deliveredAll = 0;
    var cancelledAll = 0;
    var delayed = 0;

    final heatmap = List<double>.filled(24, 0);
    final vendorCounts = <String, int>{};
    final hourBuckets = List<double>.filled(24, 0);
    final areas = <String, int>{};
    final categories = <String, int>{};
    final deliveryDurations = <double>[];

  for (final o in orders) {
      final created = o.createdAt;
      final deliveredAt = o.deliveredAt ?? (o.isDelivered ? created : null);

      if (o.isCancelled) {
        cancelledAll++;
        if (AdminDateRanges.isOnLocalDay(created, todayStart)) {
          cancelledToday++;
          final hadRider = o.deliveryBoyId.isNotEmpty;
          final s = o.orderStatus.toLowerCase();
          if (hadRider || s.contains('out') || s.contains('way')) {
            failedToday++;
          }
        }
        continue;
      }

      if (o.isDelivered) {
        deliveredAll++;
        final amount = o.total;

        // Revenue: delivered only; bucket by order createdAt (per product spec).
        if (created != null) {
          revenueAllTime += amount;
          if (AdminDateRanges.isOnLocalDay(created, todayStart)) {
            revenueToday += amount;
          }
          if (AdminDateRanges.isInRange(created, yesterdayStart, yesterdayEnd)) {
            revenueYesterday += amount;
          }
          if (AdminDateRanges.isInRange(created, weekStart, weekEnd)) {
            revenueWeekly += amount;
          }
          if (AdminDateRanges.isInRange(created, monthStart, monthEnd)) {
            revenueMonthly += amount;
          }
        }

        // Delivered today: by delivery timestamp when available.
        if (AdminDateRanges.isOnLocalDay(deliveredAt ?? created, todayStart)) {
          deliveredToday++;
          final h = (deliveredAt ?? created)!.hour;
          heatmap[h] += 1;
        }

        if (created != null && deliveredAt != null) {
          final mins = deliveredAt.difference(created).inMinutes;
          if (mins > 0 && mins < 24 * 60) deliveryDurations.add(mins.toDouble());
        }
      } else if (o.isActive) {
        pending++;
        if (o.deliveryBoyId.isEmpty) {
          unassigned++;
        } else {
          assigned++;
        }
        if (_isDelayed(o, now)) delayed++;
      }

      if (created != null && AdminDateRanges.isOnLocalDay(created, todayStart)) {
        hourBuckets[created.hour]++;
        final areaKey = o.address.trim().isEmpty
            ? 'Unknown'
            : o.address.split(',').first.trim();
        areas[areaKey] = (areas[areaKey] ?? 0) + 1;
        for (final vid in o.products.map((p) => p.vendorId).where((id) => id.isNotEmpty)) {
          vendorCounts[vid] = (vendorCounts[vid] ?? 0) + 1;
        }
      }

      for (final p in o.products) {
        final cat = p.category.trim().isEmpty ? 'General' : p.category;
        categories[cat] = (categories[cat] ?? 0) + p.itemCount;
      }
    }

    final revenue = OpsRevenueSnapshot(
      today: revenueToday,
      yesterday: revenueYesterday,
      weekly: revenueWeekly,
      monthly: revenueMonthly,
      total: revenueAllTime,
      revenueTrend7d: _revenueTrend7d(orders),
      ordersTrend7d: _ordersTrend7d(orders),
      deliveryHeatmapToday: _chartFromBuckets(heatmap),
      vendorActivityToday: _topVendors(vendorCounts),
    );

    final paidCount = orders.where((o) => o.isPaid && !o.isCancelled).length;
    final totalNonCancelled = orders.where((o) => !o.isCancelled).length;
    final codPct = totalNonCancelled == 0
        ? 0.0
        : (orders.where((o) => !o.isPaid && !o.isCancelled).length / totalNonCancelled) * 100;
    final onlinePct = totalNonCancelled == 0
        ? 0.0
        : (paidCount / totalNonCancelled) * 100;

    final rolling7Start = AdminDateRanges.rolling7Start;
    final prev7Start = rolling7Start.subtract(const Duration(days: 7));
    final weekRev = _deliveredRevenueInRange(orders, rolling7Start, weekEnd);
    final prevRev = _deliveredRevenueInRange(orders, prev7Start, rolling7Start);
    final weekOrderCount = orders
        .where(
          (o) =>
              !o.isCancelled &&
              AdminDateRanges.isInRange(o.createdAt, rolling7Start, weekEnd),
        )
        .length;
    final prevOrderCount = orders
        .where(
          (o) =>
              !o.isCancelled &&
              AdminDateRanges.isInRange(o.createdAt, prev7Start, rolling7Start),
        )
        .length;

    final avgDelivery = deliveryDurations.isEmpty
        ? 0.0
        : deliveryDurations.reduce((a, b) => a + b) / deliveryDurations.length;

    final orderAnalytics = OrderAnalyticsSnapshot(
      totalOrders: orders.length,
      pendingOrders: pending,
      deliveredOrders: deliveredAll,
      cancelledOrders: cancelledAll,
      revenue: revenueAllTime,
      revenueToday: revenueToday,
      revenueTrendPct: _pctChange(prevRev, weekRev),
      ordersTrendPct: _pctChange(prevOrderCount.toDouble(), weekOrderCount.toDouble()),
      avgDeliveryMinutes: avgDelivery,
      codPct: codPct,
      onlinePaymentPct: onlinePct,
      pendingDeliveryCount: pending,
      unassignedRiderCount: unassigned,
      delayedOrdersCount: delayed,
    );

    final peakHour = _peakHourLabel(hourBuckets);
    final topArea = areas.entries.isEmpty
        ? '—'
        : areas.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final topCat = categories.entries.isEmpty
        ? '—'
        : categories.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final utilization = pending == 0 ? 0.0 : (assigned / pending) * 100;
    final codRisk = orders
        .where(
          (o) =>
              o.isActive && !o.isPaid && o.total >= 1500,
        )
        .length;

    final peakVal = hourBuckets.reduce((a, b) => a > b ? a : b);

    final operationalInsights = OrderOperationalInsights(
      peakOrderingHour: peakHour,
      avgDeliveryMinutes: '${avgDelivery.toStringAsFixed(0)} min',
      mostActiveArea: topArea,
      topCategory: topCat,
      pendingDeliveryCount: pending,
      riderUtilizationPct: utilization,
      codRiskCount: codRisk,
      isPeakTraffic: peakVal >= 3,
    );

    return AdminAnalyticsResult(
      revenue: revenue,
      pendingOrders: pending,
      pendingAssignment: unassigned,
      assignedActiveOrders: assigned,
      deliveredToday: deliveredToday,
      failedDeliveriesToday: failedToday,
      cancelledToday: cancelledToday,
      orderAnalytics: orderAnalytics,
      operationalInsights: operationalInsights,
    );
  }

  static bool _isDelayed(AdminOrderRecord o, DateTime now) {
    final created = o.createdAt;
    if (created == null) return false;
    return now.difference(created).inMinutes > slaMinutes;
  }

  static double _deliveredRevenueInRange(
    List<AdminOrderRecord> orders,
    DateTime start,
    DateTime endExclusive,
  ) {
    var sum = 0.0;
    for (final o in orders) {
      if (!o.isDelivered || o.isCancelled) continue;
      final created = o.createdAt;
      if (created == null) continue;
      if (AdminDateRanges.isInRange(created, start, endExclusive)) {
        sum += o.total;
      }
    }
    return sum;
  }

  static List<OpsChartPoint> _revenueTrend7d(List<AdminOrderRecord> orders) {
    final now = AdminDateRanges.nowLocal;
    return List.generate(7, (i) {
      final dayStart = AdminDateRanges.startOfLocalDay(
        now.subtract(Duration(days: 6 - i)),
      );
      final dayEnd = AdminDateRanges.endOfLocalDayExclusive(dayStart);
      final sum = _deliveredRevenueInRange(orders, dayStart, dayEnd);
      return OpsChartPoint(_shortDay(dayStart), sum);
    });
  }

  static List<OpsChartPoint> _ordersTrend7d(List<AdminOrderRecord> orders) {
    final now = AdminDateRanges.nowLocal;
    return List.generate(7, (i) {
      final dayStart = AdminDateRanges.startOfLocalDay(
        now.subtract(Duration(days: 6 - i)),
      );
      final dayEnd = AdminDateRanges.endOfLocalDayExclusive(dayStart);
      final count = orders
          .where(
            (o) =>
                !o.isCancelled &&
                AdminDateRanges.isInRange(o.createdAt, dayStart, dayEnd),
          )
          .length;
      return OpsChartPoint(_shortDay(dayStart), count.toDouble());
    });
  }

  static List<OpsChartPoint> _chartFromBuckets(List<double> buckets) {
    return List.generate(
      24,
      (h) => OpsChartPoint('${h.toString().padLeft(2, '0')}h', buckets[h]),
    );
  }

  static List<OpsChartPoint> _topVendors(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(6)
        .map(
          (e) => OpsChartPoint(
            e.key.length > 8 ? '…${e.key.substring(e.key.length - 6)}' : e.key,
            e.value.toDouble(),
          ),
        )
        .toList();
  }

  static String _peakHourLabel(List<double> buckets) {
    var max = 0.0;
    var idx = -1;
    for (var i = 0; i < buckets.length; i++) {
      if (buckets[i] > max) {
        max = buckets[i];
        idx = i;
      }
    }
    if (idx < 0 || max <= 0) return '—';
    return '${idx.toString().padLeft(2, '0')}:00';
  }

  static String _shortDay(DateTime d) => DateFormat('EEE d').format(d);

  static double _pctChange(double prev, double current) {
    if (prev <= 0) return current > 0 ? 100 : 0;
    return ((current - prev) / prev) * 100;
  }
}
