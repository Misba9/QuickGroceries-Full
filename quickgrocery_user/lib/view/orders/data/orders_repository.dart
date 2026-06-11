import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/order_models.dart';
import '../services/order_cancel_api.dart';

/// Realtime read access to the user's orders + single-order updates.
///
/// We deliberately keep the read scope strict: every query is filtered to
/// the current user's `uuid` — security rules MUST enforce the same.
class OrdersRepository {
  OrdersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Live stream of all orders that belong to [uid], newest first. Used by
  /// the Orders screen tabs.
  Stream<List<LiveOrder>> watchUserOrders(String uid) {
    // Sort client-side so legacy orders without `createdAt` still appear and
    // we avoid requiring the uuid+createdAt composite index at query time.
    final query = _firestore
        .collection('orders')
        .where('uuid', isEqualTo: uid)
        .limit(100);

    return query.snapshots().map((snap) {
      final list = <LiveOrder>[];
      for (final d in snap.docs) {
        try {
          list.add(LiveOrder.fromFirestore(d.data(), d.id));
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('[OrdersRepository] parse fail ${d.id}: $e\n$st');
          }
        }
      }
      list.sort(LiveOrder.compareNewestFirst);
      return list;
    });
  }

  /// Live stream of a single order. Returns `null` once the document is
  /// deleted so the tracking screen can fall back to a friendly message.
  Stream<LiveOrder?> watchOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return LiveOrder.fromFirestore(data, snap.id);
    });
  }

  /// Cancels before pickup — server validates timing and notifies all parties.
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await OrderCancelApi().cancelByCustomer(orderId: orderId, reason: reason);
  }

  /// Convenience: fetch one order once (used by reorder flow).
  Future<LiveOrder?> fetchOrder(String orderId) async {
    final snap = await _firestore.collection('orders').doc(orderId).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return LiveOrder.fromFirestore(data, snap.id);
  }

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}
