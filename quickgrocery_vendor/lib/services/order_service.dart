import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../utils/vendor_order_utils.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'orders';

  List<OrderModel> _parseAndFilter(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String vendorId,
    String? statusFilter,
  ) {
    final orders = <OrderModel>[];
    for (final doc in docs) {
      try {
        final data = doc.data();
        if (!VendorOrderUtils.orderDataBelongsToVendor(data, vendorId)) {
          continue;
        }
        final order = OrderModel.fromFirestore(data, doc.id);
        if (statusFilter != null &&
            statusFilter != 'All' &&
            !VendorOrderUtils.matchesFilter(order, statusFilter)) {
          continue;
        }
        orders.add(order);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[OrderService] skip order ${doc.id}: $e');
        }
      }
    }
    orders.sort((a, b) {
      final da = VendorOrderUtils.parseCreatedDate(a);
      final db = VendorOrderUtils.parseCreatedDate(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return orders;
  }

  Stream<List<OrderModel>> watchVendorOrders(
    String vendorId, {
    String statusFilter = 'All',
  }) {
    return _firestore.collection(_collectionName).limit(500).snapshots().map(
          (snap) => _parseAndFilter(snap.docs, vendorId, statusFilter),
        );
  }

  Stream<List<OrderModel>> getVendorOrders(String vendorId) =>
      watchVendorOrders(vendorId);

  Stream<List<OrderModel>> getVendorOrdersByStatus(
    String vendorId,
    String status,
  ) =>
      watchVendorOrders(vendorId, statusFilter: status);

  Future<List<OrderModel>> fetchVendorOrdersOnce(String vendorId) async {
    final snap = await _firestore.collection(_collectionName).limit(500).get();
    return _parseAndFilter(snap.docs, vendorId, 'All');
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore.collection(_collectionName).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection(_collectionName).doc(orderId).update({
      'order_status': status,
      'status': _modernStatusFromLegacy(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _modernStatusFromLegacy(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliver')) return 'delivered';
    if (s.contains('cancel')) return 'cancelled';
    if (s.contains('way') || s.contains('picked')) return 'out_for_delivery';
    if (s.contains('confirm') || s.contains('accept')) return 'accepted';
    return 'pending';
  }

  Future<void> updateOrderConfirmedTime(
    String orderId,
    String confirmedTime,
  ) async {
    await _firestore.collection(_collectionName).doc(orderId).update({
      'confrimTime': confirmedTime,
    });
  }

  double getVendorRevenueFromOrder(OrderModel order, String vendorId) =>
      VendorOrderUtils.vendorRevenueFromOrder(order, vendorId);
}
