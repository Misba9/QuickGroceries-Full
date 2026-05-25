import 'package:quick_grocery_admin/core/analytics/admin_analytics_engine.dart';
import 'package:quick_grocery_admin/core/analytics/admin_order_record.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';

/// Centralized analytics API — all metrics from Firestore order data via [AdminAnalyticsEngine].
abstract final class AdminAnalyticsService {
  static AdminAnalyticsResult fromOrderMaps(List<Map<String, dynamic>> docs) {
    final records = docs
        .map((d) => AdminOrderRecord.fromMap(d, docId: d['id']?.toString()))
        .toList();
    return AdminAnalyticsEngine.compute(records);
  }

  static AdminAnalyticsResult fromOrderModels(List<OrderModel> orders) {
    final records = orders.map(AdminOrderRecord.fromOrderModel).toList();
    return AdminAnalyticsEngine.compute(records);
  }

  static double getTodayRevenue(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).revenue.today;

  static double getYesterdayRevenue(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).revenue.yesterday;

  static double getWeeklyRevenue(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).revenue.weekly;

  static double getMonthlyRevenue(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).revenue.monthly;

  static double getAllTimeRevenue(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).revenue.total;

  static int getPendingOrders(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).pendingOrders;

  static int getDeliveredToday(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).deliveredToday;

  static OpsRevenueSnapshot getRevenueSnapshot(List<Map<String, dynamic>> docs) =>
      fromOrderMaps(docs).revenue;

  static OrderAnalyticsSnapshot getOrderAnalytics(List<OrderModel> orders) =>
      fromOrderModels(orders).orderAnalytics;

  static OrderOperationalInsights getOperationalInsights(List<OrderModel> orders) =>
      fromOrderModels(orders).operationalInsights;
}
