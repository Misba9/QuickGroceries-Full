import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/view/vendor/utils/vendor_order_utils.dart';

/// Live analytics for a single vendor profile.
class VendorProfileStats {
  const VendorProfileStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.revenue,
    required this.avgRating,
    required this.activeOrders,
  });

  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double revenue;
  final double avgRating;
  final int activeOrders;

  static VendorProfileStats from({
    required List<ProductModel> products,
    required List<OrderModel> orders,
  }) {
    final activeProducts = products.where((p) => p.isActive).length;
    final cancelled = orders.where(VendorOrderUtils.isCancelled).length;
    final completed = orders.where(VendorOrderUtils.isCompleted).length;
    final pending = orders.where(VendorOrderUtils.isPending).length;
    final active = orders.where(VendorOrderUtils.isActiveOrder).length;

    final revenue = orders
        .where((o) => VendorOrderUtils.isCompleted(o))
        .fold<double>(0, (sum, o) => sum + o.getTotalAmount());

    final rated = orders.where((o) => o.isRated && o.rating > 0).toList();
    final avgRating = rated.isEmpty
        ? 0.0
        : rated.map((o) => o.rating).reduce((a, b) => a + b) / rated.length;

    return VendorProfileStats(
      totalProducts: products.length,
      activeProducts: activeProducts,
      totalOrders: orders.length,
      completedOrders: completed,
      pendingOrders: pending,
      cancelledOrders: cancelled,
      revenue: revenue,
      avgRating: avgRating,
      activeOrders: active,
    );
  }
}
