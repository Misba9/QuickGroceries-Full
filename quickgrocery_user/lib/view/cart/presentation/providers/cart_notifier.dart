import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';

import '../../data/cart_repository.dart';
import '../../data/pricing_service.dart';
import '../../domain/cart_models.dart';
import '../../domain/pricing_calculator.dart';

// ─── Infrastructure ────────────────────────────────────────────────────────

/// Single Firestore handle reused by every cart-related provider.
final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(firebaseFirestoreProvider));
});

final pricingServiceProvider = Provider<PricingService>((ref) {
  return PricingService(ref.watch(firebaseFirestoreProvider));
});

/// Live pricing config — surface as [AsyncValue] so consumers can render
/// loading/error skeletons without the cart needing to also model that.
final pricingConfigProvider = StreamProvider<PricingConfig>((ref) {
  return ref.watch(pricingServiceProvider).watch();
});

/// Random per-app-launch id used to drop our own Firestore writes when
/// we read them back through the snapshot listener (echo suppression).
final cartClientIdProvider = Provider<String>((ref) {
  final r = Random();
  return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
});

// ─── Notifier ──────────────────────────────────────────────────────────────

/// Owns cart state and bridges bidirectionally with legacy
/// `CategoryService.selectedProduct`.
///
/// **Initialization rules** — kept here to make future maintenance easy:
///   1. [build] *must* return a fully constructed [CartState] without
///      ever writing to `state`. Reading or writing `state` from inside
///      [build] before it returns throws "Tried to read the state of an
///      uninitialized provider."
///   2. All side-effects that emit state (auth subscriptions, pricing
///      listener, Firestore cart subscription) are deferred via
///      [Future.microtask] so they only run *after* [build] returns.
///   3. [attachLegacy] is called exactly once by [CartBootstrap] from the
///      widget tree. It is safe to call before or after the cart has
///      hydrated.
///   4. `[_disposed]` short-circuits any deferred callback that races with
///      `ref.invalidate` / app teardown.
class CartNotifier extends Notifier<CartState> {
  CategoryService? _legacy;
  StreamSubscription<CartSnapshotData?>? _cartSub;
  StreamSubscription<User?>? _authSub;
  ProviderSubscription<AsyncValue<PricingConfig>>? _pricingSub;
  Timer? _debounce;
  bool _suppressLegacyEcho = false;
  bool _disposed = false;
  String? _uid;

  static const _calc = PricingCalculator();

  @override
  CartState build() {
    ref.onDispose(_handleDispose);

    // Defer all state-writing setup until *after* [build] returns. This
    // is the canonical fix for "Bad state: Tried to read the state of an
    // uninitialized provider" when listeners synchronously want to push
    // state during initialization.
    Future.microtask(_initSubscriptions);

    return CartState.empty;
  }

  void _handleDispose() {
    _disposed = true;
    _cartSub?.cancel();
    _authSub?.cancel();
    _pricingSub?.close();
    _debounce?.cancel();
    _legacy?.removeListener(_onLegacyChanged);
  }

  void _initSubscriptions() {
    if (_disposed) return;
    _bootPricing();
    _bootAuth();
  }

  /// Wires the legacy `package:provider` cart store to this notifier so
  /// the existing app keeps working unchanged. Safe to call multiple
  /// times — only the first attach actually subscribes.
  void attachLegacy(CategoryService legacy) {
    if (_disposed || _legacy == legacy) return;
    _legacy?.removeListener(_onLegacyChanged);
    _legacy = legacy;
    _legacy!.addListener(_onLegacyChanged);

    // If the cart already has items (we hydrated before the bridge was
    // attached), push them down to the legacy service immediately so any
    // `package:provider`-based UI catches up without waiting for the next
    // remote snapshot.
    if (state.items.isNotEmpty) {
      _replaceLegacyItems(state.items);
    } else if (legacy.selectedProduct.isNotEmpty) {
      // Conversely, if the legacy service already has items (e.g., the
      // user added something before sign-in), seed [state] from it.
      final next = legacy.selectedProduct
          .map(CartItem.fromProduct)
          .toList(growable: false);
      state = state.copyWith(items: next, clearError: true);
      _recomputeBill();
      _scheduleSync();
    }
  }

  // ── Subscriptions ────────────────────────────────────────────────────

  void _bootPricing() {
    _pricingSub = ref.listen<AsyncValue<PricingConfig>>(
      pricingConfigProvider,
      (_, next) {
        if (_disposed) return;
        next.whenData((config) {
          if (_disposed) return;
          state = state.copyWith(pricing: config);
          _recomputeBill();
        });
      },
      fireImmediately: true,
    );
  }

  void _bootAuth() {
    _authSub = FirebaseAuth.instance
        .authStateChanges()
        .listen(_onUserChanged, onError: (Object e, StackTrace st) {
      if (kDebugMode) debugPrint('Cart auth stream error: $e');
    });
    // Sync once with the current user as soon as we land here. We're
    // already deferred behind a microtask from [build], so writing state
    // is safe.
    _onUserChanged(FirebaseAuth.instance.currentUser);
  }

  void _onUserChanged(User? user) {
    if (_disposed) return;
    final uid = user?.uid;
    if (_uid == uid) return;
    _uid = uid;
    _cartSub?.cancel();

    if (uid == null) {
      // Signed-out → clear everything but don't error.
      state = CartState.empty;
      _replaceLegacyItems(const []);
      return;
    }

    state = state.copyWith(isHydrating: true, clearError: true);

    final repo = ref.read(cartRepositoryProvider);
    _cartSub = repo.watch(uid).listen(
      _onRemoteSnapshot,
      onError: (Object e, StackTrace st) {
        if (_disposed) return;
        if (kDebugMode) debugPrint('Cart watch error: $e');
        state = state.copyWith(
          isHydrating: false,
          errorMessage: 'Failed to load your cart',
        );
      },
    );
  }

  void _onRemoteSnapshot(CartSnapshotData? snap) {
    if (_disposed) return;
    final ourClientId = ref.read(cartClientIdProvider);

    if (snap == null) {
      if (state.items.isNotEmpty) _replaceLegacyItems(const []);
      state = state.copyWith(
        items: const [],
        clearCoupon: true,
        isHydrating: false,
        clearError: true,
      );
      _recomputeBill();
      return;
    }

    // Drop echoes of our own writes, unless we're still hydrating —
    // then we want every snapshot so the first frame is correct.
    if (snap.clientId == ourClientId && !state.isHydrating) {
      return;
    }

    state = state.copyWith(
      items: snap.items,
      coupon: snap.coupon,
      isHydrating: false,
      clearError: true,
    );
    _replaceLegacyItems(snap.items);
    _recomputeBill();
  }

  // ── Legacy bridge ────────────────────────────────────────────────────

  void _replaceLegacyItems(List<CartItem> items) {
    final legacy = _legacy;
    if (legacy == null) return;
    _suppressLegacyEcho = true;
    try {
      legacy.selectedProduct
        ..clear()
        ..addAll(items.map((e) => e.toLegacyProduct()));
      legacy.notifyCartListeners();
    } finally {
      _suppressLegacyEcho = false;
    }
  }

  void _onLegacyChanged() {
    if (_disposed || _suppressLegacyEcho) return;
    final legacy = _legacy;
    if (legacy == null) return;

    final next = legacy.selectedProduct
        .map(CartItem.fromProduct)
        .toList(growable: false);

    if (_itemsEqual(state.items, next)) {
      _recomputeBill();
      return;
    }
    state = state.copyWith(items: next, clearError: true);
    _recomputeBill();
    _scheduleSync();
  }

  bool _itemsEqual(List<CartItem> a, List<CartItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].productId != b[i].productId) return false;
      if (a[i].itemCount != b[i].itemCount) return false;
      if (a[i].selectedWeightInGrams != b[i].selectedWeightInGrams) {
        return false;
      }
    }
    return true;
  }

  // ── Public API ───────────────────────────────────────────────────────

  void addProduct(ProductModel product) {
    if (_disposed) return;
    final items = [...state.items];
    final idx = items.indexWhere((c) => c.productId == product.id);
    if (idx == -1) {
      items.add(CartItem.fromProduct(product, itemCount: 1));
    } else {
      final cur = items[idx];
      final cap = cur.maxOrder == 0 ? 999 : cur.maxOrder;
      final next = (cur.itemCount + 1).clamp(1, cap);
      items[idx] = cur.copyWith(itemCount: next);
    }
    _writeLocal(items);
  }

  void increment(String productId) {
    if (_disposed) return;
    final items = [...state.items];
    final idx = items.indexWhere((c) => c.productId == productId);
    if (idx == -1) return;
    final cur = items[idx];
    final cap = cur.maxOrder == 0 ? 999 : cur.maxOrder;
    if (cur.itemCount >= cap) return;
    items[idx] = cur.copyWith(itemCount: cur.itemCount + 1);
    _writeLocal(items);
  }

  void decrement(String productId) {
    if (_disposed) return;
    final items = [...state.items];
    final idx = items.indexWhere((c) => c.productId == productId);
    if (idx == -1) return;
    final cur = items[idx];
    if (cur.itemCount <= 1) {
      items.removeAt(idx);
    } else {
      items[idx] = cur.copyWith(itemCount: cur.itemCount - 1);
    }
    _writeLocal(items);
  }

  void remove(String productId) {
    if (_disposed) return;
    final items =
        state.items.where((c) => c.productId != productId).toList();
    _writeLocal(items);
  }

  void updateWeight(String productId, int grams) {
    if (_disposed) return;
    final items = [...state.items];
    final idx = items.indexWhere((c) => c.productId == productId);
    if (idx == -1) return;
    items[idx] = items[idx].copyWith(selectedWeightInGrams: grams);
    _writeLocal(items);
  }

  void applyCoupon(AppliedCoupon coupon) {
    if (_disposed) return;
    state = state.copyWith(coupon: coupon, clearError: true);
    _recomputeBill();
    _scheduleSync();
  }

  void removeCoupon() {
    if (_disposed) return;
    state = state.copyWith(clearCoupon: true);
    _recomputeBill();
    _scheduleSync();
  }

  Future<void> clear() async {
    if (_disposed) return;
    state = state.copyWith(items: const [], clearCoupon: true);
    _recomputeBill();
    _replaceLegacyItems(const []);

    final uid = _uid;
    if (uid == null) return;

    try {
      await ref.read(cartRepositoryProvider).clear(uid);
    } catch (e) {
      if (_disposed) return;
      if (kDebugMode) debugPrint('Cart clear failed: $e');
      // Surface a non-fatal banner — local state is already cleared.
      state = state.copyWith(errorMessage: 'Cart cleared locally');
    }
  }

  /// One-shot retry helper exposed to the error banner.
  void retry() {
    if (_disposed) return;
    state = state.copyWith(clearError: true);
    _onUserChanged(FirebaseAuth.instance.currentUser);
  }

  // ── Internals ────────────────────────────────────────────────────────

  void _writeLocal(List<CartItem> items) {
    state = state.copyWith(items: items, clearError: true);
    _replaceLegacyItems(items);
    _recomputeBill();
    _scheduleSync();
  }

  void _recomputeBill() {
    try {
      final bill = _calc.compute(
        items: state.items,
        config: state.pricing,
        coupon: state.coupon,
      );
      state = state.copyWith(bill: bill);
    } catch (e) {
      if (kDebugMode) debugPrint('Bill compute failed: $e');
    }
  }

  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _flush);
  }

  Future<void> _flush() async {
    if (_disposed) return;
    final uid = _uid;
    if (uid == null) return;

    if (state.items.isEmpty) {
      try {
        await ref.read(cartRepositoryProvider).clear(uid);
      } catch (e) {
        if (kDebugMode) debugPrint('Cart clear (flush) failed: $e');
      }
      return;
    }

    state = state.copyWith(isSyncing: true);
    try {
      await ref.read(cartRepositoryProvider).save(
            uid: uid,
            items: state.items,
            coupon: state.coupon,
            bill: state.bill,
            clientId: ref.read(cartClientIdProvider),
          );
      if (_disposed) return;
      state = state.copyWith(isSyncing: false, clearError: true);
    } catch (e) {
      if (_disposed) return;
      if (kDebugMode) debugPrint('Cart sync failed: $e');
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Cart sync failed',
      );
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

// ─── Derived providers used by checkout / cart screens ─────────────────────

/// Async delivery charge for the user's pinCode. Lifted to a Riverpod
/// `FutureProvider.family` so the cart screen and checkout screen don't
/// each spawn their own `FutureBuilder` with redundant Firestore reads.
final zoneDeliveryProvider =
    FutureProvider.autoDispose.family<double, String?>((ref, pin) async {
  if (pin == null || pin.isEmpty) return 0;
  // We pull this from the legacy service the rest of the app already
  // holds open, so we don't open a second connection here.
  final dz = ref.read(deliveryZoneServiceProvider);
  if (dz == null) return 0;
  try {
    final zone = await dz.getZoneByPinCode(pin);
    return (zone?.deliveryCharge ?? 0).toDouble();
  } catch (e) {
    if (kDebugMode) debugPrint('Zone fetch failed: $e');
    return 0;
  }
});

/// Bridges the legacy `DeliveryZoneService` (registered via
/// `package:provider`) to Riverpod. [CartBootstrap] sets this on app
/// boot so [zoneDeliveryProvider] can use it without depending on
/// `BuildContext`.
final deliveryZoneServiceProvider =
    StateProvider<DeliveryZoneService?>((ref) => null);
