import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_delivery/core/firestore_query_errors.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

/// Firestore-backed COD payment collection list (server-sorted when indexes exist).
enum PaymentCollectionFilter {
  pending,
  collected,
  all,
}

enum _PaymentQueryTier {
  optimized,
  riderSorted,
  riderOnly,
}

/// UI state for Collect Payment tabs.
sealed class PaymentCollectionListState {
  const PaymentCollectionListState();

  const factory PaymentCollectionListState.loading() =
      PaymentCollectionLoading;

  const factory PaymentCollectionListState.loaded(List<OrderModel> orders) =
      PaymentCollectionLoaded;

  const factory PaymentCollectionListState.unavailable() =
      PaymentCollectionUnavailable;
}

final class PaymentCollectionLoading extends PaymentCollectionListState {
  const PaymentCollectionLoading();
}

final class PaymentCollectionLoaded extends PaymentCollectionListState {
  const PaymentCollectionLoaded(this.orders);
  final List<OrderModel> orders;
}

final class PaymentCollectionUnavailable extends PaymentCollectionListState {
  const PaymentCollectionUnavailable();
}

class PaymentCollectionOrdersService {
  PaymentCollectionOrdersService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _codMethod = 'cod';
  static const _riderLimit = 300;

  Stream<PaymentCollectionListState> watchState({
    required String riderId,
    required PaymentCollectionFilter filter,
  }) {
    if (riderId.isEmpty) {
      return Stream.value(const PaymentCollectionLoaded([]));
    }

    late StreamController<PaymentCollectionListState> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;

    void listen(
      Query<Map<String, dynamic>> query, {
      required _PaymentQueryTier tier,
    }) {
      sub?.cancel();
      sub = query.snapshots().listen(
        (snap) {
          final orders = _mapDocs(
            snap.docs,
            filter: filter,
            tier: tier,
          );
          controller.add(PaymentCollectionLoaded(orders));
        },
        onError: (Object error, StackTrace stack) {
          if (FirestoreQueryErrors.isMissingIndex(error)) {
            switch (tier) {
              case _PaymentQueryTier.optimized:
                FirestoreQueryErrors.log(
                  'PaymentCollectionOrdersService: optimized index missing, '
                  'try rider+createdAt (filter=$filter)',
                  error,
                  stack,
                );
                listen(
                  _riderSortedQuery(riderId),
                  tier: _PaymentQueryTier.riderSorted,
                );
                return;
              case _PaymentQueryTier.riderSorted:
                FirestoreQueryErrors.log(
                  'PaymentCollectionOrdersService: rider+createdAt index '
                  'missing, using rider-only (filter=$filter)',
                  error,
                  stack,
                );
                listen(
                  _riderOnlyQuery(riderId),
                  tier: _PaymentQueryTier.riderOnly,
                );
                return;
              case _PaymentQueryTier.riderOnly:
                break;
            }
          }
          FirestoreQueryErrors.log(
            'PaymentCollectionOrdersService: query failed '
            '(filter=$filter tier=$tier)',
            error,
            stack,
          );
          controller.add(const PaymentCollectionUnavailable());
        },
      );
    }

    controller = StreamController<PaymentCollectionListState>(
      onListen: () {
        controller.add(const PaymentCollectionLoading());
        listen(
          _optimizedQuery(riderId, filter),
          tier: _PaymentQueryTier.optimized,
        );
      },
      onCancel: () => sub?.cancel(),
    );

    return controller.stream;
  }

  Query<Map<String, dynamic>> _optimizedQuery(
    String riderId,
    PaymentCollectionFilter filter,
  ) {
    Query<Map<String, dynamic>> query = _db
        .collection('orders')
        .where('deliveryBoyId', isEqualTo: riderId)
        .where('paymentMethod', isEqualTo: _codMethod);

    switch (filter) {
      case PaymentCollectionFilter.pending:
        query = query.where('paymentStatus', isEqualTo: 'pending');
        break;
      case PaymentCollectionFilter.collected:
        query = query.where('paymentStatus', isEqualTo: 'paid');
        break;
      case PaymentCollectionFilter.all:
        break;
    }

    return query.orderBy('createdAt', descending: true);
  }

  Query<Map<String, dynamic>> _riderSortedQuery(String riderId) {
    return _db
        .collection('orders')
        .where('deliveryBoyId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .limit(_riderLimit);
  }

  /// No composite index required — filter/sort in memory when indexes are not deployed.
  Query<Map<String, dynamic>> _riderOnlyQuery(String riderId) {
    return _db
        .collection('orders')
        .where('deliveryBoyId', isEqualTo: riderId)
        .limit(_riderLimit);
  }

  static List<OrderModel> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required PaymentCollectionFilter filter,
    required _PaymentQueryTier tier,
  }) {
    final needsClientFilter = tier != _PaymentQueryTier.optimized;
    final needsClientSort = tier == _PaymentQueryTier.riderOnly;

    var list = docs
        .map((d) => OrderModel.fromFirestore(d.data(), d.id))
        .where((o) => !needsClientFilter || _matchesFilter(o, filter))
        .toList();

    if (needsClientSort) {
      list.sort((a, b) {
        final at = _sortKey(a);
        final bt = _sortKey(b);
        return bt.compareTo(at);
      });
    }

    return list;
  }

  static DateTime _sortKey(OrderModel order) {
    return order.createdAt ??
        DateTime.tryParse(order.createdDate.trim()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static bool _matchesFilter(OrderModel order, PaymentCollectionFilter filter) {
    final method = order.paymentMethod.toLowerCase();
    final isCod = method == 'cod' || method == 'cash_on_delivery';
    if (!isCod) return false;

    switch (filter) {
      case PaymentCollectionFilter.pending:
        return order.payment.requiresCodCollection;
      case PaymentCollectionFilter.collected:
        return order.payment.isPaymentCollected;
      case PaymentCollectionFilter.all:
        return true;
    }
  }
}
