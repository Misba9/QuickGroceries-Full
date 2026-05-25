import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_analytics_service.dart';

/// Revenue / trend aggregation — delegates to [AdminAnalyticsEngine].
abstract final class OpsRevenueAggregator {
  static OpsRevenueSnapshot compute(List<Map<String, dynamic>> orders) =>
      AdminAnalyticsService.fromOrderMaps(orders).revenue;
}
