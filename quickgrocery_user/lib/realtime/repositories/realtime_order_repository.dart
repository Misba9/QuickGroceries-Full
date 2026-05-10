import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/realtime/services/realtime_order_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';

/// Buckets the user's orders into the three sections the Orders screen
/// renders. Lets the UI render straight from a single stream tick.
class UserOrders {
  const UserOrders({
    required this.all,
    required this.upcoming,
    required this.delivered,
    required this.cancelled,
  });

  final List<OrderModel> all;
  final List<OrderModel> upcoming;
  final List<OrderModel> delivered;
  final List<OrderModel> cancelled;

  static const empty = UserOrders(
    all: [],
    upcoming: [],
    delivered: [],
    cancelled: [],
  );
}

class RealtimeOrderRepository {
  RealtimeOrderRepository(this._service);
  final RealtimeOrderService _service;

  Stream<UserOrders> watchUserOrders(String uid) {
    return _service.watchUserOrders(uid).map(_bucket).handleError(
          _throwHomeFailure('Failed to watch orders.'),
        );
  }

  Stream<OrderModel?> watchOrder(String id) {
    return _service.watchOrder(id).map((doc) {
      if (!doc.exists) return null;
      try {
        return OrderModel.fromFirestore(doc.data()!, doc.id);
      } catch (e) {
        if (kDebugMode) debugPrint('[RealtimeOrderRepo] parse fail: $e');
        return null;
      }
    }).handleError(_throwHomeFailure('Failed to watch order.'));
  }

  // ── helpers ────────────────────────────────────────────────────────

  UserOrders _bucket(QuerySnapshot<Map<String, dynamic>> snap) {
    final all = <OrderModel>[];
    for (final d in snap.docs) {
      try {
        all.add(OrderModel.fromFirestore(d.data(), d.id));
      } catch (e) {
        if (kDebugMode) debugPrint('[RealtimeOrderRepo] parse fail ${d.id}: $e');
      }
    }
    all.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    final upcoming = <OrderModel>[];
    final delivered = <OrderModel>[];
    final cancelled = <OrderModel>[];
    for (final o in all) {
      if (o.isCancelled) {
        cancelled.add(o);
      } else if (o.isDelivered) {
        delivered.add(o);
      } else {
        upcoming.add(o);
      }
    }

    return UserOrders(
      all: all,
      upcoming: upcoming,
      delivered: delivered,
      cancelled: cancelled,
    );
  }

  void Function(Object, StackTrace) _throwHomeFailure(String message) {
    return (Object error, StackTrace stackTrace) {
      throw HomeFailure(message, code: _codeOf(error), cause: error);
    };
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
