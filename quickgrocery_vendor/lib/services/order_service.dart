import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'orders';

  /// Get all orders for a specific vendor
  /// Filters orders where at least one product belongs to the vendor
  Stream<List<OrderModel>> getVendorOrders(String vendorId) {
    return _firestore
        .collection(_collectionName)
        .orderBy('created_date', descending: true)
        .snapshots()
        .map((snapshot) {
      final orders = <OrderModel>[];
      for (var doc in snapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc.data(), doc.id);
          // Check if any product in the order belongs to this vendor
          final hasVendorProduct = order.products.any(
            (product) => product.vendorId == vendorId,
          );
          if (hasVendorProduct) {
            orders.add(order);
          }
        } catch (e) {
          // Skip invalid orders
          continue;
        }
      }
      return orders;
    });
  }

  /// Get orders by status for a vendor
  Stream<List<OrderModel>> getVendorOrdersByStatus(
    String vendorId,
    String status,
  ) {
    return _firestore
        .collection(_collectionName)
        .where('order_status', isEqualTo: status)
        .orderBy('created_date', descending: true)
        .snapshots()
        .map((snapshot) {
      final orders = <OrderModel>[];
      for (var doc in snapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc.data(), doc.id);
          final hasVendorProduct = order.products.any(
            (product) => product.vendorId == vendorId,
          );
          if (hasVendorProduct) {
            orders.add(order);
          }
        } catch (e) {
          continue;
        }
      }
      return orders;
    });
  }

  /// Get a single order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(orderId).update({
        'order_status': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update order confirmed time
  Future<void> updateOrderConfirmedTime(String orderId, String confirmedTime) async {
    try {
      await _firestore.collection(_collectionName).doc(orderId).update({
        'confrimTime': confirmedTime,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate vendor's revenue from an order
  double getVendorRevenueFromOrder(OrderModel order, String vendorId) {
    double revenue = 0.0;
    int vendorProductCount = 0;
    int totalProductCount = 0;

    for (var product in order.products) {
      totalProductCount += product.itemCount;
      if (product.vendorId == vendorId) {
        revenue += product.price * product.itemCount;
        vendorProductCount += product.itemCount;
      }
    }

    // Calculate vendor's share of delivery charge (proportional)
    if (totalProductCount > 0 && order.deliveryCharge > 0) {
      final deliveryShare = (order.deliveryCharge * vendorProductCount) / totalProductCount;
      revenue += deliveryShare;
    }

    return revenue;
  }
}

