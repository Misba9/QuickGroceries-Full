import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_models.dart';
import 'cart_notifier.dart';
import 'delivery_slots_provider.dart';
import 'package:quickgrocery/core/order/order_placement_log.dart';
import 'package:quickgrocery/core/user/checkout_preferences_store.dart';

/// Local checkout state with session persistence for payment, address, instructions.
class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController(this._ref) : super(CheckoutState.fresh()) {
    Future.microtask(_bootstrap);
    _cartListener = _ref.listen<CartState>(cartProvider, (prev, next) {
      if (!mounted) return;
      if (next.isEmpty && state.isPlacingOrder) {
        state = state.copyWith(isPlacingOrder: false, clearError: true);
      }
    });
  }

  final Ref _ref;
  ProviderSubscription<CartState>? _cartListener;
  bool _hydrated = false;
  bool _placementLock = false;

  Future<void> _bootstrap() async {
    if (!mounted) return;
    _seedSlot();

    final saved = await CheckoutPreferencesStore.loadInitial();
    if (!mounted || saved == null) return;

    state = state.copyWith(
      paymentMethod: saved.paymentMethod,
      selectedAddressIndex: saved.selectedAddressIndex,
      instructions: saved.instructions,
    );
    _hydrated = true;
  }

  void _seedSlot() {
    if (!mounted) return;
    if (state.slot != null) return;
    try {
      final slots = _ref.read(deliverySlotsProvider);
      if (slots.isNotEmpty) {
        state = state.copyWith(slot: slots.first);
      }
    } catch (_) {}
  }

  void _persist() {
    if (!_hydrated && state == CheckoutState.initial) return;
    CheckoutPreferencesStore.persistFromState(state);
  }

  /// Synchronous guard — call at the first line of the Place Order tap handler.
  bool tryBeginPlacement() {
    if (!mounted) return false;
    if (_placementLock || state.isPlacingOrder) {
      OrderPlacementLog.duplicateTapIgnored(
        idempotencyKey: state.idempotencyKey,
      );
      return false;
    }
    _placementLock = true;
    state = state.copyWith(isPlacingOrder: true, clearError: true);
    OrderPlacementLog.loadingStarted(idempotencyKey: state.idempotencyKey);
    return true;
  }

  /// Unlocks the button when validation/auth fails before any order API call.
  void cancelPlacement() {
    if (!mounted) return;
    _placementLock = false;
    state = state.copyWith(isPlacingOrder: false, clearError: true);
  }

  void finishPlacementSuccess() {
    if (!mounted) return;
    // Stay locked + loading until checkout screen disposes after navigation.
    state = state.copyWith(isPlacingOrder: true, clearError: true);
  }

  /// Re-enables the button. Keeps the same idempotency key so retries dedupe.
  void finishPlacementFailure() {
    if (!mounted) return;
    _placementLock = false;
    state = state.copyWith(isPlacingOrder: false, clearError: true);
  }

  void selectAddress(int index) {
    if (!mounted || state.isPlacingOrder) return;
    state = state.copyWith(selectedAddressIndex: index);
    _persist();
  }

  void selectSlot(DeliverySlot slot) {
    if (!mounted || state.isPlacingOrder) return;
    state = state.copyWith(slot: slot);
  }

  void setInstructions(DeliveryInstructions instructions) {
    if (!mounted || state.isPlacingOrder) return;
    state = state.copyWith(instructions: instructions);
    _persist();
  }

  void selectPaymentMethod(PaymentMethod method) {
    if (!mounted || state.isPlacingOrder) return;
    state = state.copyWith(paymentMethod: method);
    _persist();
  }

  void setDeliveryTip(double amount) {
    if (!mounted || state.isPlacingOrder) return;
    state = state.copyWith(deliveryTipAmount: amount < 0 ? 0 : amount);
  }

  void setPlacingOrder(bool placing) {
    if (!mounted) return;
    if (placing) {
      tryBeginPlacement();
      return;
    }
    _placementLock = false;
    state = state.copyWith(isPlacingOrder: false, clearError: true);
  }

  void clearError() {
    if (!mounted) return;
    state = state.copyWith(clearError: true);
  }

  void setError(String message) {
    if (!mounted) return;
    finishPlacementFailure();
    state = state.copyWith(errorMessage: message);
  }

  @override
  void dispose() {
    _cartListener?.close();
    super.dispose();
  }
}

final checkoutControllerProvider =
    StateNotifierProvider.autoDispose<CheckoutController, CheckoutState>(
  CheckoutController.new,
);
