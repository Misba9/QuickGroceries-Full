
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_models.dart';
import 'cart_notifier.dart';
import 'delivery_slots_provider.dart';
import 'package:quickgrocery/core/user/checkout_preferences_store.dart';

/// Local checkout state with session persistence for payment, address, instructions.
class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController(this._ref) : super(CheckoutState.initial) {
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

  void selectAddress(int index) {
    if (!mounted) return;
    state = state.copyWith(selectedAddressIndex: index);
    _persist();
  }

  void selectSlot(DeliverySlot slot) {
    if (!mounted) return;
    state = state.copyWith(slot: slot);
  }

  void setInstructions(DeliveryInstructions instructions) {
    if (!mounted) return;
    state = state.copyWith(instructions: instructions);
    _persist();
  }

  void selectPaymentMethod(PaymentMethod method) {
    if (!mounted) return;
    state = state.copyWith(paymentMethod: method);
    _persist();
  }

  void setDeliveryTip(double amount) {
    if (!mounted) return;
    state = state.copyWith(deliveryTipAmount: amount < 0 ? 0 : amount);
  }

  void setPlacingOrder(bool placing) {
    if (!mounted) return;
    state = state.copyWith(isPlacingOrder: placing, clearError: true);
  }

  void clearError() {
    if (!mounted) return;
    state = state.copyWith(clearError: true);
  }

  void setError(String message) {
    if (!mounted) return;
    state = state.copyWith(isPlacingOrder: false, errorMessage: message);
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
