import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/order_lifecycle.dart';
import 'package:quick_grocery_admin/core/utils/duration_format.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_priority.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_status_theme.dart';

class OpsRevenueSnapshot {
  const OpsRevenueSnapshot({
    this.today = 0,
    this.yesterday = 0,
    this.weekly = 0,
    this.monthly = 0,
    this.total = 0,
    this.revenueTrend7d = const [],
    this.ordersTrend7d = const [],
    this.deliveryHeatmapToday = const [],
    this.vendorActivityToday = const [],
  });

  final double today;
  final double yesterday;
  final double weekly;
  final double monthly;
  final double total;
  final List<OpsChartPoint> revenueTrend7d;
  final List<OpsChartPoint> ordersTrend7d;
  final List<OpsChartPoint> deliveryHeatmapToday;
  final List<OpsChartPoint> vendorActivityToday;
}

class OpsChartPoint {
  const OpsChartPoint(this.label, this.value);
  final String label;
  final double value;
}

enum OpsTimelineStep { placed, assigned, outForDelivery, delivered }

class OpsLiveOrder {
  const OpsLiveOrder({
    required this.id,
    required this.customerName,
    required this.vendorName,
    required this.riderName,
    required this.status,
    required this.statusLabel,
    required this.paymentLabel,
    required this.elapsedLabel,
    required this.etaLabel,
    required this.total,
    required this.priority,
    required this.isNew,
    required this.timeline,
    required this.raw,
  });

  final String id;
  final String customerName;
  final String vendorName;
  final String riderName;
  final OpsQueueStatus status;
  final String statusLabel;
  final String paymentLabel;
  final String elapsedLabel;
  final String etaLabel;
  final double total;
  final OpsOrderPriority priority;
  final bool isNew;
  final Map<OpsTimelineStep, bool> timeline;
  final Map<String, dynamic> raw;

  factory OpsLiveOrder.fromMap(
    Map<String, dynamic> d, {
    required Map<String, String> vendorNames,
    required Map<String, String> riderNames,
    required Set<String> previousActiveIds,
  }) {
    final id = d['id']?.toString() ?? '';
    final status = OpsOrderStatusTheme.resolve(d);
    final vendorIds = OpsFirestoreHelpers.vendorIdsFromOrder(d);
    final vendorLabel = vendorIds
        .map((vid) => vendorNames[vid] ?? vid)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final riderId = OpsFirestoreHelpers.riderId(d);
    final riderLabel = riderId.isEmpty
        ? 'Unassigned'
        : (riderNames[riderId] ?? 'Rider');

    final created = OpsFirestoreHelpers.createdAt(d);
    final elapsed = _elapsed(created);
    final eta = _etaLabel(d, created);

    return OpsLiveOrder(
      id: id,
      customerName: (d['customer_name'] ?? d['customerName'] ?? 'Customer')
          .toString(),
      vendorName: vendorLabel.isEmpty ? '—' : vendorLabel,
      riderName: riderLabel,
      status: status,
      statusLabel: OpsOrderStatusTheme.label(status),
      paymentLabel: OpsFirestoreHelpers.paymentStatusLabel(d),
      elapsedLabel: elapsed,
      etaLabel: eta,
      total: OpsFirestoreHelpers.orderTotal(d),
      priority: OpsOrderPriorityRules.compute(d),
      isNew: !previousActiveIds.contains(id),
      timeline: _timeline(d),
      raw: d,
    );
  }

  static Map<OpsTimelineStep, bool> _timeline(Map<String, dynamic> d) {
    final status = OrderLifecycle.resolveFromOrderData(d);
    final hasRider = OpsFirestoreHelpers.riderId(d).isNotEmpty;
    return {
      OpsTimelineStep.placed: true,
      OpsTimelineStep.assigned:
          hasRider || status == OrderLifecycle.deliveryAssigned,
      OpsTimelineStep.outForDelivery:
          status == OrderLifecycle.outForDelivery ||
          OpsFirestoreHelpers.orderStatusRaw(d).contains('way'),
      OpsTimelineStep.delivered: OpsFirestoreHelpers.isDelivered(d),
    };
  }

  static String _elapsed(DateTime? created) =>
      DurationFormat.formatElapsed(created, suffixAgo: false);

  static String _etaLabel(Map<String, dynamic> d, DateTime? created) {
    if (OpsFirestoreHelpers.isDelivered(d)) return 'Delivered';
    if (OpsFirestoreHelpers.isCancelled(d)) return '—';
    return DurationFormat.formatEta(createdAt: created);
  }
}

class OpsActivityEntry {
  const OpsActivityEntry({
    required this.id,
    required this.summary,
    required this.action,
    required this.entityType,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final String summary;
  final String action;
  final String entityType;
  final IconData icon;
  final Color color;
  final DateTime? createdAt;

  factory OpsActivityEntry.fromMap(Map<String, dynamic> a) {
    final action = (a['action'] ?? '').toString().toLowerCase();
    final entity = (a['entityType'] ?? a['entity_type'] ?? '').toString();
    final summary =
        (a['summary'] ?? a['message'] ?? action).toString().trim();
    final (icon, color) = _style(action, entity);
    return OpsActivityEntry(
      id: a['id']?.toString() ?? '',
      summary: summary.isEmpty ? 'Activity' : summary,
      action: action,
      entityType: entity,
      icon: icon,
      color: color,
      createdAt: OpsFirestoreHelpers.parseDate(a['createdAt'] ?? a['created_at']),
    );
  }

  static (IconData, Color) _style(String action, String entity) {
    if (action.contains('refund') || action.contains('payment_fail')) {
      return (Icons.currency_exchange, const Color(0xFFB45309));
    }
    if (action.contains('cancel')) {
      return (Icons.cancel_outlined, const Color(0xFFB91C1C));
    }
    if (action.contains('order') || entity == 'order') {
      return (Icons.receipt_long_outlined, const Color(0xFF1D4ED8));
    }
    if (action.contains('vendor') || entity == 'vendor') {
      return (Icons.storefront_outlined, const Color(0xFF6D28D9));
    }
    if (action.contains('user') || entity == 'customer') {
      return (Icons.person_add_alt_1, const Color(0xFF047857));
    }
    if (action.contains('rider') || entity == 'delivery_boy') {
      return (Icons.delivery_dining, const Color(0xFF0E7490));
    }
    if (action.contains('stock') || action.contains('inventory')) {
      return (Icons.inventory_2_outlined, const Color(0xFFEA580C));
    }
    return (Icons.notifications_none, const Color(0xFF475569));
  }
}
