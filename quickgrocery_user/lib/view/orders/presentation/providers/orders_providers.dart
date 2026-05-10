import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart'
    show firebaseFirestoreProvider;

import '../../data/invoice_service.dart';
import '../../data/orders_repository.dart';
import '../../data/rider_location_repository.dart';
import '../../data/support_repository.dart';
import '../../domain/eta_calculator.dart';
import '../../domain/order_models.dart';

// ── Repositories ───────────────────────────────────────────────────────────

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(firebaseFirestoreProvider));
});

final riderLocationRepositoryProvider =
    Provider<RiderLocationRepository>((ref) {
  return RiderLocationRepository(ref.watch(firebaseFirestoreProvider));
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(firebaseFirestoreProvider));
});

final invoiceServiceProvider = Provider<InvoiceService>((_) {
  return const InvoiceService();
});

final etaCalculatorProvider = Provider<EtaCalculator>((_) {
  return const EtaCalculator();
});

// ── Streams ────────────────────────────────────────────────────────────────

/// Live stream of all orders for the current user. We rebuild the stream
/// when auth changes so signing in/out swaps cleanly.
final userOrdersStreamProvider =
    StreamProvider.autoDispose<List<LiveOrder>>((ref) {
  final repo = ref.watch(ordersRepositoryProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    return const Stream<List<LiveOrder>>.empty();
  }
  return repo.watchUserOrders(uid);
});

/// Live single-order stream by id.
final orderByIdStreamProvider =
    StreamProvider.autoDispose.family<LiveOrder?, String>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).watchOrder(orderId);
});

/// Live rider location keyed by deliveryBoyId.
final riderLocationStreamProvider =
    StreamProvider.autoDispose.family<RiderLocation?, String>((ref, id) {
  return ref.watch(riderLocationRepositoryProvider).watch(id);
});

/// Per-order ETA. Rebuilt when either the order or the rider position emits.
/// We throttle rebuilds via the underlying autoDispose family — Riverpod
/// already dedupes identical results, so polling is unnecessary.
final etaProvider =
    Provider.autoDispose.family<Duration, String>((ref, orderId) {
  final orderAsync = ref.watch(orderByIdStreamProvider(orderId));
  final order = orderAsync.value;
  if (order == null) return Duration.zero;

  final riderAsync = order.hasRider
      ? ref.watch(riderLocationStreamProvider(order.deliveryBoyId))
      : const AsyncValue<RiderLocation?>.data(null);

  return ref
      .watch(etaCalculatorProvider)
      .estimate(order, riderAsync.value);
});

/// Live chat thread for an order.
final supportMessagesStreamProvider =
    StreamProvider.autoDispose.family<List<SupportMessage>, String>(
  (ref, orderId) =>
      ref.watch(supportRepositoryProvider).watch(orderId),
);

// ── Filtered tab views ─────────────────────────────────────────────────────

enum OrdersTab { processing, delivered, cancelled }

extension OrdersTabFilter on OrdersTab {
  bool matches(LiveOrder o) {
    switch (this) {
      case OrdersTab.processing:
        return !o.isCancelled && !o.isDelivered;
      case OrdersTab.delivered:
        return !o.isCancelled && o.isDelivered;
      case OrdersTab.cancelled:
        return o.isCancelled;
    }
  }
}

final filteredOrdersProvider =
    Provider.autoDispose.family<AsyncValue<List<LiveOrder>>, OrdersTab>(
  (ref, tab) {
    final asyncList = ref.watch(userOrdersStreamProvider);
    return asyncList.whenData(
      (list) => list.where(tab.matches).toList(growable: false),
    );
  },
);
