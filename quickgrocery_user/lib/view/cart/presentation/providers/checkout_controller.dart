import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_models.dart';
import 'cart_notifier.dart';
import 'delivery_slots_provider.dart';

/// Local-only state for the checkout flow (selected address index, slot,
/// instructions, payment method, placing-order spinner). Lives only while
/// the user is on the checkout screen.
///
/// **Initialization order**
///   - Default state is [CheckoutState.initial] (slot = null, COD).
///   - The first delivery slot is selected lazily via [_seedSlot] which
///     is invoked **after** the StateNotifier finishes constructing, so
///     reading [deliverySlotsProvider] cannot trigger an "uninitialized
///     provider" error.
///   - Methods are no-ops after [dispose] (StateNotifier handles this
///     itself by throwing on stale state writes; we add explicit guards
///     for clarity).
class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController(this._ref) : super(CheckoutState.initial) {
    // Defer dependent provider reads until after super() finishes.
    Future.microtask(_seedSlot);
    // React to cart changes (e.g. cart cleared / hydrated late) by
    // resetting transient flags so the UI doesn't get stuck spinning.
    _cartListener = _ref.listen<CartState>(cartProvider, (prev, next) {
      if (!mounted) return;
      if (next.isEmpty && state.isPlacingOrder) {
        state = state.copyWith(isPlacingOrder: false, clearError: true);
      }
    });
  }

  final Ref _ref;
  ProviderSubscription<CartState>? _cartListener;

  void _seedSlot() {
    if (!mounted) return;
    if (state.slot != null) return;
    try {
      final slots = _ref.read(deliverySlotsProvider);
      if (slots.isNotEmpty) {
        state = state.copyWith(slot: slots.first);
      }
    } catch (_) {
      // Slot list not available yet — UI will let the user pick manually.
    }
  }

  void selectAddress(int index) {
    if (!mounted) return;
    state = state.copyWith(selectedAddressIndex: index);
  }

  void selectSlot(DeliverySlot slot) {
    if (!mounted) return;
    state = state.copyWith(slot: slot);
  }

  void setInstructions(DeliveryInstructions instructions) {
    if (!mounted) return;
    state = state.copyWith(instructions: instructions);
  }

  void selectPaymentMethod(PaymentMethod method) {
    if (!mounted) return;
    state = state.copyWith(paymentMethod: method);
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
