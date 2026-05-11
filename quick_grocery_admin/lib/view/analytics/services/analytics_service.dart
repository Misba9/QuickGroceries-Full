import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/view/analytics/domain/order_analytics_parser.dart';
import 'package:quick_grocery_admin/view/analytics/models/analytics_snapshot.dart';

enum AnalyticsDatePreset {
  today,
  week,
  month,
  year,
  all,
  custom,
}

/// Realtime quick-commerce analytics for the admin dashboard.
class AnalyticsService extends ChangeNotifier {
  AnalyticsService() {
    _ordersSub = FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .listen(_onOrders, onError: (Object e, StackTrace st) {
      if (kDebugMode) debugPrint('[AnalyticsService] orders stream error: $e');
    });
    _loadSideCollections();
  }

  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  Timer? _debounce;

  List<Map<String, dynamic>> _orders = [];
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _bannerDocs = [];

  AnalyticsDatePreset preset = AnalyticsDatePreset.month;
  DateTimeRange? customRange;

  AnalyticsSnapshot _snapshot =
      AnalyticsSnapshot.empty(_presetLabel(AnalyticsDatePreset.month));
  AnalyticsSnapshot get snapshot => _snapshot;

  bool sideLoading = true;
  String? loadError;
  int _couponCount = 0;

  static String _presetLabel(AnalyticsDatePreset p) {
    switch (p) {
      case AnalyticsDatePreset.today:
        return 'Today';
      case AnalyticsDatePreset.week:
        return 'Last 7 days';
      case AnalyticsDatePreset.month:
        return 'Last 30 days';
      case AnalyticsDatePreset.year:
        return 'Last 365 days';
      case AnalyticsDatePreset.all:
        return 'All time';
      case AnalyticsDatePreset.custom:
        return 'Custom';
    }
  }

  void _onOrders(QuerySnapshot<Map<String, dynamic>> snap) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _orders = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      _recompute();
    });
  }

  Future<void> _loadSideCollections() async {
    sideLoading = true;
    notifyListeners();
    try {
      final c = await _firestore.collection('customers').get();
      _customers = c.docs
          .map((d) => CustomerModel.fromFirestore(d.data(), d.id))
          .toList();

      final p = await _firestore.collection('products').get();
      _products = p.docs
          .map((d) => ProductModel.fromFirestore(d.data(), d.id))
          .toList();

      final b = await _firestore.collection('banners').get();
      _bannerDocs = b.docs.map((d) => d.data()).toList();

      try {
        final cp = await _firestore.collection('coupons').get();
        _couponCount = cp.docs.length;
      } catch (_) {
        _couponCount = 0;
      }

      loadError = null;
    } catch (e) {
      loadError = e.toString();
    } finally {
      sideLoading = false;
      _recompute();
    }
  }

  void setPreset(AnalyticsDatePreset p, {DateTimeRange? range}) {
    preset = p;
    customRange = p == AnalyticsDatePreset.custom ? range : null;
    _recompute();
  }

  (DateTime, DateTime) _window() {
    final now = DateTime.now();
    switch (preset) {
      case AnalyticsDatePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, now);
      case AnalyticsDatePreset.week:
        return (now.subtract(const Duration(days: 7)), now);
      case AnalyticsDatePreset.month:
        return (now.subtract(const Duration(days: 30)), now);
      case AnalyticsDatePreset.year:
        return (now.subtract(const Duration(days: 365)), now);
      case AnalyticsDatePreset.all:
        return (DateTime(2000), now);
      case AnalyticsDatePreset.custom:
        final r = customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            );
        return (r.start, r.end);
    }
  }

  (DateTime, DateTime) _previousWindow(DateTime start, DateTime end) {
    final len = end.difference(start);
    final prevEnd = start.subtract(const Duration(seconds: 1));
    final prevStart = prevEnd.subtract(len);
    return (prevStart, prevEnd);
  }

  void _recompute() {
    final (start, end) = _window();
    final (pStart, pEnd) = _previousWindow(start, end);
    final label = preset == AnalyticsDatePreset.custom && customRange != null
        ? '${DateFormat.MMMd().format(customRange!.start)} – ${DateFormat.MMMd().format(customRange!.end)}'
        : _presetLabel(preset);

    bool inWin(DateTime? t) =>
        t != null && !t.isBefore(start) && !t.isAfter(end);
    bool inPrev(DateTime? t) =>
        t != null && !t.isBefore(pStart) && !t.isAfter(pEnd);

    var rev = 0.0;
    var prevRev = 0.0;
    var disc = 0.0;
    var ref = 0.0;
    final daily = <String, double>{};
    final statusSlices = <String, double>{};
    var total = 0;
    var pending = 0;
    var delivered = 0;
    var cancelled = 0;
    var refundish = 0;
    final productUnits = <String, int>{};
    final categoryUnits = <String, int>{};
    final buyerStats = <String, _BuyerAgg>{};
    final boyLoads = <String, int>{};
    final zones = <String, int>{};
    var pendPay = 0;
    var outDel = 0;
    final durations = <double>[];
    var delayed = 0;
    final hourly = List<double>.filled(24, 0);

    for (final m in _orders) {
      final t = OrderAnalyticsParser.parseCreatedAt(m);

      if (inWin(t)) {
        total++;
        final st = (m['status'] ?? m['order_status'] ?? 'unknown').toString();
        statusSlices[st] = (statusSlices[st] ?? 0) + 1;

        if (OrderAnalyticsParser.isCancelled(m)) {
          cancelled++;
        } else if (OrderAnalyticsParser.isDelivered(m)) {
          delivered++;
        } else {
          pending++;
        }

        if ((m['paymentStatus'] ?? '').toString() == 'pending' &&
            (m['paymentMethod'] ?? '').toString() != 'cod') {
          pendPay++;
        }
        if ((m['status'] ?? '').toString() == 'out_for_delivery') {
          outDel++;
        }

        if (t != null) {
          hourly[t.hour] = hourly[t.hour] + 1;
        }

        if (OrderAnalyticsParser.isRevenueEligible(m)) {
          final r = OrderAnalyticsParser.revenueFromOrder(m);
          rev += r;
          disc += OrderAnalyticsParser.discountFromOrder(m);
          ref += OrderAnalyticsParser.refundFromOrder(m);
          if (ref > 0) refundish++;

          if (t != null) {
            final dayKey = DateFormat('MMM d').format(t);
            daily[dayKey] = (daily[dayKey] ?? 0) + r;
          }

          for (final p in (m['products'] as List?) ?? const []) {
            if (p is Map<String, dynamic>) {
              final name = (p['name'] ?? 'Item').toString();
              final qty = (p['itemCount'] ?? 0) as num? ?? 0;
              productUnits[name] = (productUnits[name] ?? 0) + qty.toInt();
              final cat = (p['category'] ?? 'General').toString();
              categoryUnits[cat] = (categoryUnits[cat] ?? 0) + qty.toInt();
            }
          }

          final uid = OrderAnalyticsParser.customerUid(m);
          if (uid.isNotEmpty) {
            buyerStats.putIfAbsent(uid, () => _BuyerAgg());
            buyerStats[uid]!.count++;
            buyerStats[uid]!.revenue += r;
            buyerStats[uid]!.name =
                (m['customer_name'] ?? 'Customer').toString();
          }

          final bid = (m['deliveryBoyId'] ?? '').toString();
          if (bid.isNotEmpty) {
            boyLoads[bid] = (boyLoads[bid] ?? 0) + 1;
          }

          final z = OrderAnalyticsParser.zoneKey(m);
          if (z != null) {
            zones[z] = (zones[z] ?? 0) + 1;
          }

          final dur = OrderAnalyticsParser.deliveryDuration(m);
          if (dur != null) {
            final mins = dur.inMinutes.toDouble();
            durations.add(mins);
            if (mins > 45) delayed++;
          }
        }
      }

      if (inPrev(t) && OrderAnalyticsParser.isRevenueEligible(m)) {
        prevRev += OrderAnalyticsParser.revenueFromOrder(m);
      }
    }

    var growth = 0.0;
    if (prevRev > 0) {
      growth = (rev - prevRev) / prevRev * 100;
    }

    final dailyList = daily.entries
        .map((e) => ChartPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final top = productUnits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topRows = top
        .take(12)
        .map((e) => TopProductRow(name: e.key, unitsSold: e.value))
        .toList();

    final zoneRows = zones.entries
        .map((e) => ZoneOrderRow(e.key, e.value))
        .toList()
      ..sort((a, b) => b.orderCount.compareTo(a.orderCount));

    final buyers = buyerStats.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final topBuyers = buyers
        .take(8)
        .map(
          (e) => BuyerRow(
            e.value.name,
            e.value.count,
            e.value.revenue,
          ),
        )
        .toList();

    final returning = buyerStats.values.where((v) => v.count > 1).length;
    final active = buyerStats.length;
    final retention =
        (active > 0 ? (returning / active * 100).clamp(0, 100) : 0.0)
            .toDouble();

    var newCust = 0;
    for (final c in _customers) {
      final cd = DateTime.tryParse(c.createdDate);
      if (inWin(cd)) newCust++;
    }

    double? avgDel;
    if (durations.isNotEmpty) {
      avgDel = durations.reduce((a, b) => a + b) / durations.length;
    }

    var bannerViews = 0;
    var bannerClicks = 0;
    for (final b in _bannerDocs) {
      bannerViews += (b['viewCount'] as num?)?.toInt() ?? 0;
      bannerClicks += (b['clickCount'] as num?)?.toInt() ?? 0;
    }

    var lowStock = 0;
    var outStock = 0;
    for (final p in _products) {
      final q = int.tryParse(p.stock) ?? 0;
      if (q <= 0) {
        outStock++;
      } else if (q <= 5) {
        lowStock++;
      }
    }

    final successDen = delivered + cancelled;
    final successRate = (successDen > 0
            ? (delivered / successDen * 100).clamp(0, 100)
            : 100.0)
        .toDouble();

    final profit = rev - disc - ref;

    final dated = <(DateTime, String)>[];
    for (final m in _orders) {
      final t = OrderAnalyticsParser.parseCreatedAt(m);
      final id = m['id']?.toString() ?? '';
      if (t != null && id.isNotEmpty) dated.add((t, id));
    }
    dated.sort((a, b) => b.$1.compareTo(a.$1));
    final recentIds = dated.take(8).map((e) => e.$2).toList();

    _snapshot = AnalyticsSnapshot(
      generatedAt: DateTime.now(),
      rangeLabel: label,
      deliveredRevenue: rev,
      revenueGrowthPercent: growth,
      dailyRevenue: dailyList,
      orderStatusSlices: statusSlices,
      totalOrders: total,
      pendingOrders: pending,
      deliveredOrders: delivered,
      cancelledOrders: cancelled,
      returnOrRefundOrders: refundish,
      orderSuccessRate: successRate,
      topProducts: topRows,
      categoryUnits: categoryUnits,
      newCustomersInRange: newCust,
      returningBuyers: returning,
      activeBuyers: active,
      topBuyers: topBuyers,
      estimatedRetentionPercent: retention,
      avgDeliveryMinutes: avgDel,
      delayedDeliveries: delayed,
      deliveryBoyOrderLoads: boyLoads,
      highOrderZones: zoneRows.take(8).toList(),
      pendingPayments: pendPay,
      outForDelivery: outDel,
      recentOrderIds: recentIds,
      couponDocuments: _couponCount,
      bannerViews: bannerViews,
      bannerClicks: bannerClicks,
      lowStockSkus: lowStock,
      outOfStockSkus: outStock,
      estimatedGrossProfit: profit,
      hourlyOrderHeat: hourly,
    );
    notifyListeners();
  }

  Future<void> refreshSideData() => _loadSideCollections();

  Future<void> exportCsvDeliveredRevenue(BuildContext? context) async {
    final (start, end) = _window();
    final rows = <List<String>>[
      ['order_id', 'created_at', 'revenue', 'customer', 'status'],
    ];
    for (final m in _orders) {
      final t = OrderAnalyticsParser.parseCreatedAt(m);
      if (t == null || t.isBefore(start) || t.isAfter(end)) continue;
      if (!OrderAnalyticsParser.isRevenueEligible(m)) continue;
      rows.add([
        m['id']?.toString() ?? '',
        t.toIso8601String(),
        OrderAnalyticsParser.revenueFromOrder(m).toStringAsFixed(2),
        (m['customer_name'] ?? '').toString(),
        (m['status'] ?? m['order_status'] ?? '').toString(),
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    await Clipboard.setData(ClipboardData(text: csv));
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV copied to clipboard — paste into Excel or Sheets'),
        ),
      );
    }
  }

  Future<void> exportPdfSummary() async {
    final s = _snapshot;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Quick Grocery — Analytics')),
          pw.Text('Range: ${s.rangeLabel}'),
          pw.SizedBox(height: 12),
          pw.Text(
              'Delivered revenue: ₹${s.deliveredRevenue.toStringAsFixed(0)}'),
          pw.Text(
              'Growth vs prev: ${s.revenueGrowthPercent.toStringAsFixed(1)}%'),
          pw.Text(
              'Orders — total ${s.totalOrders}, delivered ${s.deliveredOrders}, cancelled ${s.cancelledOrders}'),
          pw.Text('Top products (units):'),
          ...s.topProducts.map(
            (p) => pw.Bullet(text: '${p.name}: ${p.unitsSold}'),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }
}

class _BuyerAgg {
  int count = 0;
  double revenue = 0;
  String name = '';
}
