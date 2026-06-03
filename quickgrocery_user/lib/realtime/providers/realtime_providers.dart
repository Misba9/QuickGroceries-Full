import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/realtime/models/inventory_snapshot.dart';
import 'package:quickgrocery/realtime/models/notification_item.dart';
import 'package:quickgrocery/realtime/models/rider_live_location.dart';
import 'package:quickgrocery/realtime/repositories/realtime_delivery_repository.dart';
import 'package:quickgrocery/realtime/repositories/realtime_notification_repository.dart';
import 'package:quickgrocery/realtime/repositories/realtime_order_repository.dart';
import 'package:quickgrocery/realtime/repositories/realtime_product_repository.dart';
import 'package:quickgrocery/realtime/services/realtime_banner_service.dart';
import 'package:quickgrocery/realtime/services/realtime_delivery_service.dart';
import 'package:quickgrocery/realtime/services/realtime_notification_service.dart';
import 'package:quickgrocery/realtime/services/realtime_order_service.dart';
import 'package:quickgrocery/realtime/services/realtime_product_service.dart';

// ── Infrastructure ─────────────────────────────────────────────────────────

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Live `currentUser` — null when signed out. Drives every per-user
/// stream below; flips re-subscribe everything automatically.
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).maybeWhen(
        data: (u) => u?.uid,
        orElse: () => null,
      );
});

// ── Services ───────────────────────────────────────────────────────────────

final realtimeProductServiceProvider = Provider<RealtimeProductService>((ref) {
  return RealtimeProductService(firestore: ref.watch(firebaseFirestoreProvider));
});

final realtimeOrderServiceProvider = Provider<RealtimeOrderService>((ref) {
  return RealtimeOrderService(firestore: ref.watch(firebaseFirestoreProvider));
});

final realtimeBannerServiceProvider = Provider<RealtimeBannerService>((ref) {
  return RealtimeBannerService(firestore: ref.watch(firebaseFirestoreProvider));
});

final realtimeDeliveryServiceProvider = Provider<RealtimeDeliveryService>((ref) {
  return RealtimeDeliveryService(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final realtimeNotificationServiceProvider =
    Provider<RealtimeNotificationService>((ref) {
  return RealtimeNotificationService(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

// ── Repositories ───────────────────────────────────────────────────────────

final realtimeProductRepositoryProvider =
    Provider<RealtimeProductRepository>((ref) {
  return RealtimeProductRepository(ref.watch(realtimeProductServiceProvider));
});

final realtimeOrderRepositoryProvider =
    Provider<RealtimeOrderRepository>((ref) {
  return RealtimeOrderRepository(ref.watch(realtimeOrderServiceProvider));
});

final realtimeDeliveryRepositoryProvider =
    Provider<RealtimeDeliveryRepository>((ref) {
  return RealtimeDeliveryRepository(
    ref.watch(realtimeDeliveryServiceProvider),
  );
});

final realtimeNotificationRepositoryProvider =
    Provider<RealtimeNotificationRepository>((ref) {
  return RealtimeNotificationRepository(
    ref.watch(realtimeNotificationServiceProvider),
  );
});

// ── Public realtime streams ────────────────────────────────────────────────

/// Live single product. Emits null when the doc is removed.
final productStreamProvider =
    StreamProvider.autoDispose.family<ProductModel?, String>((ref, id) {
  return ref.watch(realtimeProductRepositoryProvider).watchProduct(id);
});

/// Live products by category — includes inactive ones; UI may filter.
final productsByCategoryStreamProvider = StreamProvider.autoDispose
    .family<List<ProductModel>, String>((ref, categoryId) {
  return ref
      .watch(realtimeProductRepositoryProvider)
      .watchByCategory(categoryId, limit: 200);
});

/// Live inventory map for an arbitrary id list — feed cart / wishlist
/// screens with their current ids and they patch as Vendor/Admin
/// updates land.
final inventoryStreamProvider = StreamProvider.autoDispose
    .family<Map<String, InventorySnapshot>, List<String>>((ref, ids) {
  // Family equality on List<String>: callers should pass an unmodifiable
  // sorted list to keep the cache key stable.
  return ref.watch(realtimeProductRepositoryProvider).watchInventoryFor(ids);
});

/// Live low-stock products — used on the "running low" rail.
final lowStockStreamProvider =
    StreamProvider.autoDispose.family<List<ProductModel>, int>((ref, threshold) {
  return ref
      .watch(realtimeProductRepositoryProvider)
      .watchLowStock(threshold: threshold);
});

/// User's orders, bucketed (upcoming / delivered / cancelled).
final ordersStreamProvider =
    StreamProvider.autoDispose<UserOrders>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null || uid.isEmpty) {
    return Stream.value(UserOrders.empty);
  }
  return ref.watch(realtimeOrderRepositoryProvider).watchUserOrders(uid);
});

/// Live single order — drives the live tracking screen.
final orderStreamProvider =
    StreamProvider.autoDispose.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(realtimeOrderRepositoryProvider).watchOrder(orderId);
});

/// Live rider profile + telemetry. Powers map markers, ETA chips,
/// online indicator. Pass empty id to short-circuit.
final deliveryTrackingProvider = StreamProvider.autoDispose
    .family<RiderLiveLocation?, String>((ref, deliveryBoyId) {
  return ref
      .watch(realtimeDeliveryRepositoryProvider)
      .watchRider(deliveryBoyId);
});

/// In-app notifications for the current user (descending, limit 50).
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationItem>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null || uid.isEmpty) return Stream.value(const []);
  return ref.watch(realtimeNotificationRepositoryProvider).watch(uid);
});

/// Bell badge — unread count, signed-out → 0.
final unreadNotificationsCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null || uid.isEmpty) return Stream.value(0);
  return ref
      .watch(realtimeNotificationRepositoryProvider)
      .watchUnreadCount(uid);
});

