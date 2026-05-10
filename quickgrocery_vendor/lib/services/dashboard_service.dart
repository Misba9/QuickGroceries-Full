import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class DashboardStats {
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int pendingOrders;
  final int totalProducts;
  final double totalRevenue;
  final double todayRevenue;
  final int cancelledOrders;

  DashboardStats({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.totalProducts,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.cancelledOrders,
  });
}

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard statistics for a vendor
  Future<DashboardStats> getVendorStats(String vendorId) async {
    try {
      // Get all orders
      final ordersSnapshot = await _firestore.collection('orders').get();

      // Filter orders that belong to this vendor
      final vendorOrders = <OrderModel>[];
      for (var doc in ordersSnapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc.data(), doc.id);
          // Check if any product in the order belongs to this vendor
          final hasVendorProduct = order.products.any(
            (product) => product.vendorId == vendorId,
          );
          if (hasVendorProduct) {
            vendorOrders.add(order);
          }
        } catch (e) {
          // Skip invalid orders
          continue;
        }
      }

      // Calculate statistics
      int totalOrders = vendorOrders.length;
      int activeOrders = 0;
      int completedOrders = 0;
      int pendingOrders = 0;
      int cancelledOrders = 0;
      double totalRevenue = 0.0;
      double todayRevenue = 0.0;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      for (var order in vendorOrders) {
        // Calculate revenue only for vendor's products in the order
        double orderRevenue = 0.0;
        int vendorProductCount = 0;
        int totalProductCount = 0;

        for (var product in order.products) {
          totalProductCount += product.itemCount;
          if (product.vendorId == vendorId) {
            orderRevenue += product.price * product.itemCount;
            vendorProductCount += product.itemCount;
          }
        }

        // Calculate vendor's share of delivery charge (proportional)
        double deliveryShare = 0.0;
        if (totalProductCount > 0 && order.deliveryCharge > 0) {
          deliveryShare =
              (order.deliveryCharge * vendorProductCount) / totalProductCount;
        }
        orderRevenue += deliveryShare;

        // Count order status
        if (order.isCancelled) {
          cancelledOrders++;
        } else if (order.isDelivered) {
          completedOrders++;
          if (order.isPaid) {
            totalRevenue += orderRevenue;
            // Check if order was created today
            try {
              final orderDate = DateTime.parse(order.createdDate);
              if (orderDate.isAfter(todayStart)) {
                todayRevenue += orderRevenue;
              }
            } catch (e) {
              // If date parsing fails, skip today revenue calculation
            }
          }
        } else if (order.orderStatus.toLowerCase() == 'pending' ||
            order.orderStatus.toLowerCase() == 'confirmed') {
          pendingOrders++;
        } else {
          activeOrders++;
        }
      }

      // Get total products count
      final productsSnapshot = await _firestore
          .collection('products')
          .where('vendor_id', isEqualTo: vendorId)
          .get();

      int totalProducts = productsSnapshot.docs.length;

      return DashboardStats(
        totalOrders: totalOrders,
        activeOrders: activeOrders,
        completedOrders: completedOrders,
        pendingOrders: pendingOrders,
        totalProducts: totalProducts,
        totalRevenue: totalRevenue,
        todayRevenue: todayRevenue,
        cancelledOrders: cancelledOrders,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get real-time stream of vendor orders count
  Stream<int> getVendorOrdersCountStream(String vendorId) {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc.data(), doc.id);
          final hasVendorProduct = order.products.any(
            (product) => product.vendorId == vendorId,
          );
          if (hasVendorProduct) count++;
        } catch (e) {
          continue;
        }
      }
      return count;
    });
  }
}
