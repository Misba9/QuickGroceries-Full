import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/order_lifecycle.dart';
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

  /// Realtime vendor orders — merges `vendorIds` array + legacy `vendorId` queries.
  Stream<List<OrderModel>> watchVendorOrders(
    String vendorId, {
    String statusFilter = 'All',
  }) {
    final controller = StreamController<List<OrderModel>>.broadcast();
    List<OrderModel> fromArray = [];
    List<OrderModel> fromSingle = [];

    void emitMerged() {
      final map = <String, OrderModel>{};
      for (final o in [...fromArray, ...fromSingle]) {
        map[o.id] = o;
      }
      var merged = map.values.toList()
        ..sort((a, b) {
          final da = VendorOrderUtils.parseCreatedDate(a);
          final db = VendorOrderUtils.parseCreatedDate(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
      if (statusFilter != 'All') {
        merged = merged
            .where((o) => VendorOrderUtils.matchesFilter(o, statusFilter))
            .toList();
      }
      if (!controller.isClosed) {
        controller.add(merged);
      }
    }

    StreamSubscription? subArray;
    StreamSubscription? subSingle;

    controller.onListen = () {
      subArray = _firestore
          .collection(_collectionName)
          .where('vendorIds', arrayContains: vendorId)
          .limit(200)
          .snapshots()
          .listen(
        (snap) {
          fromArray = _parseAndFilter(snap.docs, vendorId, null);
          if (kDebugMode) {
            debugPrint(
              '[VendorNotify] orders stream (vendorIds): ${fromArray.length}',
            );
          }
          emitMerged();
        },
        onError: (e) {
          if (kDebugMode) {
            debugPrint('[OrderService] vendorIds stream error: $e');
          }
        },
      );

      subSingle = _firestore
          .collection(_collectionName)
          .where('vendorId', isEqualTo: vendorId)
          .limit(200)
          .snapshots()
          .listen(
        (snap) {
          fromSingle = _parseAndFilter(snap.docs, vendorId, null);
          if (kDebugMode) {
            debugPrint(
              '[VendorNotify] orders stream (vendorId): ${fromSingle.length}',
            );
          }
          emitMerged();
        },
        onError: (e) {
          if (kDebugMode) {
            debugPrint('[OrderService] vendorId stream error: $e');
          }
        },
      );
    };

    controller.onCancel = () async {
      await subArray?.cancel();
      await subSingle?.cancel();
    };

    return controller.stream;
  }

  Stream<List<OrderModel>> getVendorOrders(String vendorId) =>
      watchVendorOrders(vendorId);

  Stream<List<OrderModel>> getVendorOrdersByStatus(
    String vendorId,
    String status,
  ) =>
      watchVendorOrders(vendorId, statusFilter: status);

  Future<List<OrderModel>> fetchVendorOrdersOnce(String vendorId) async {
    final arraySnap = await _firestore
        .collection(_collectionName)
        .where('vendorIds', arrayContains: vendorId)
        .limit(200)
        .get();
    final singleSnap = await _firestore
        .collection(_collectionName)
        .where('vendorId', isEqualTo: vendorId)
        .limit(200)
        .get();
    final map = <String, OrderModel>{};
    for (final o in _parseAndFilter(arraySnap.docs, vendorId, 'All')) {
      map[o.id] = o;
    }
    for (final o in _parseAndFilter(singleSnap.docs, vendorId, 'All')) {
      map[o.id] = o;
    }
    return map.values.toList();
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore.collection(_collectionName).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> updateOrderStatus(String orderId, String statusId) async {
    await _firestore.collection(_collectionName).doc(orderId).update({
      'order_status': OrderLifecycle.legacyLabel(statusId),
      'status': statusId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptOrder(String orderId, {required String vendorId}) async {
    await _firestore.collection(_collectionName).doc(orderId).update({
      'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.vendorAccepted),
      'status': OrderLifecycle.vendorAccepted,
      'confrimTime': DateTime.now().toIso8601String(),
      'vendorAcceptedAt': FieldValue.serverTimestamp(),
      'vendorAcceptedBy': vendorId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectOrder(String orderId, {required String vendorId, String? reason}) async {
    await _firestore.collection(_collectionName).doc(orderId).update({
      'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.cancelledByVendor),
      'status': OrderLifecycle.cancelledByVendor,
      'isCancelled': true,
      'cancelledBy': 'vendor',
      'cancelledAt': FieldValue.serverTimestamp(),
      'vendorRejectedAt': FieldValue.serverTimestamp(),
      'vendorRejectedBy': vendorId,
      if (reason != null && reason.trim().isNotEmpty) 'cancelReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markPreparing(String orderId) async {
    await updateOrderStatus(orderId, OrderLifecycle.packing);
  }

  Future<void> markReadyForPickup(String orderId) async {
    await updateOrderStatus(orderId, OrderLifecycle.readyForPickup);
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

  double getVendorOrderTotal(OrderModel order, String vendorId) {
    var total = 0.0;
    for (final p in order.products.where((x) => x.vendorId == vendorId)) {
      total += p.price * p.itemCount;
    }
    return total;
  }

  Stream<OrderModel?> watchOrderById(String orderId) {
    return _firestore.collection(_collectionName).doc(orderId).snapshots().map(
      (snap) {
        if (!snap.exists || snap.data() == null) return null;
        return OrderModel.fromFirestore(snap.data()!, snap.id);
      },
    );
  }

  Future<void> assignDeliveryBoy({
    required String orderId,
    required String deliveryBoyId,
    required String riderName,
    required String riderPhone,
  }) async {
    await _firestore.collection(_collectionName).doc(orderId).update({
      'deliveryBoyId': deliveryBoyId,
      'delivery_boy_id': deliveryBoyId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.riderAssigned),
      'status': OrderLifecycle.riderAssigned,
      'assignedAt': FieldValue.serverTimestamp(),
      'assignedBy': 'vendor',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
