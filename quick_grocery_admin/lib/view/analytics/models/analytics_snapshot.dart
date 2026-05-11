import 'package:flutter/foundation.dart';

/// Immutable point for charts (x label + value).
@immutable
class ChartPoint {
  const ChartPoint(this.label, this.value);
  final String label;
  final double value;
}

@immutable
class TopProductRow {
  const TopProductRow({
    required this.name,
    required this.unitsSold,
    this.category,
  });
  final String name;
  final int unitsSold;
  final String? category;
}

@immutable
class ZoneOrderRow {
  const ZoneOrderRow(this.label, this.orderCount);
  final String label;
  final int orderCount;
}

@immutable
class BuyerRow {
  const BuyerRow(this.displayName, this.deliveredCount, this.revenue);
  final String displayName;
  final int deliveredCount;
  final double revenue;
}

/// Aggregated admin analytics for the selected date window.
@immutable
class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.generatedAt,
    required this.rangeLabel,
    required this.deliveredRevenue,
    required this.revenueGrowthPercent,
    required this.dailyRevenue,
    required this.orderStatusSlices,
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.returnOrRefundOrders,
    required this.orderSuccessRate,
    required this.topProducts,
    required this.categoryUnits,
    required this.newCustomersInRange,
    required this.returningBuyers,
    required this.activeBuyers,
    required this.topBuyers,
    required this.estimatedRetentionPercent,
    required this.avgDeliveryMinutes,
    required this.delayedDeliveries,
    required this.deliveryBoyOrderLoads,
    required this.highOrderZones,
    required this.pendingPayments,
    required this.outForDelivery,
    required this.recentOrderIds,
    required this.couponDocuments,
    required this.bannerViews,
    required this.bannerClicks,
    required this.lowStockSkus,
    required this.outOfStockSkus,
    required this.estimatedGrossProfit,
    required this.hourlyOrderHeat,
  });

  final DateTime generatedAt;
  final String rangeLabel;

  /// Sum of [OrderAnalyticsParser.revenueFromOrder] for delivered, eligible rows.
  final double deliveredRevenue;

  /// vs previous window of same length (null first run → 0).
  final double revenueGrowthPercent;

  final List<ChartPoint> dailyRevenue;

  /// Pie slices: label → value (count or revenue depending on builder).
  final Map<String, double> orderStatusSlices;

  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int returnOrRefundOrders;
  final double orderSuccessRate;

  final List<TopProductRow> topProducts;
  final Map<String, int> categoryUnits;

  final int newCustomersInRange;
  final int returningBuyers;
  final int activeBuyers;
  final List<BuyerRow> topBuyers;
  final double estimatedRetentionPercent;

  final double? avgDeliveryMinutes;
  final int delayedDeliveries;
  final Map<String, int> deliveryBoyOrderLoads;
  final List<ZoneOrderRow> highOrderZones;

  final int pendingPayments;
  final int outForDelivery;
  final List<String> recentOrderIds;

  final int couponDocuments;
  final int bannerViews;
  final int bannerClicks;

  final int lowStockSkus;
  final int outOfStockSkus;

  /// Revenue − discounts − refunds (vendor / ops payouts need external data).
  final double estimatedGrossProfit;

  /// 24 buckets — order counts by local hour for “heatmap-style” insight.
  final List<double> hourlyOrderHeat;

  static AnalyticsSnapshot empty(String rangeLabel) => AnalyticsSnapshot(
        generatedAt: DateTime.now(),
        rangeLabel: rangeLabel,
        deliveredRevenue: 0,
        revenueGrowthPercent: 0,
        dailyRevenue: const [],
        orderStatusSlices: const {},
        totalOrders: 0,
        pendingOrders: 0,
        deliveredOrders: 0,
        cancelledOrders: 0,
        returnOrRefundOrders: 0,
        orderSuccessRate: 0,
        topProducts: const [],
        categoryUnits: const {},
        newCustomersInRange: 0,
        returningBuyers: 0,
        activeBuyers: 0,
        topBuyers: const [],
        estimatedRetentionPercent: 0,
        avgDeliveryMinutes: null,
        delayedDeliveries: 0,
        deliveryBoyOrderLoads: const {},
        highOrderZones: const [],
        pendingPayments: 0,
        outForDelivery: 0,
        recentOrderIds: const [],
        couponDocuments: 0,
        bannerViews: 0,
        bannerClicks: 0,
        lowStockSkus: 0,
        outOfStockSkus: 0,
        estimatedGrossProfit: 0,
        hourlyOrderHeat: List<double>.filled(24, 0),
      );
}
