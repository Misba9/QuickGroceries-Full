import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/order_models.dart';

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
    final query = _firestore
        .collection('orders')
        .where('uuid', isEqualTo: uid)
        .limit(100);

    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => LiveOrder.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  /// Cancels the order on the user's side. We mirror both the legacy flag
  /// (`isCancelled = true`) and the modern `status` field so admin/delivery
  /// apps reading either field stay in sync.
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _firestore.collection('orders').doc(orderId).update({
      'isCancelled': true,
      'status': OrderStatus.cancelled.id,
      'cancelReason': reason ?? '',
      'cancelledBy': 'customer',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
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
