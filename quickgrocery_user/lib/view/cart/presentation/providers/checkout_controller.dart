import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_models.dart';
import 'delivery_slots_provider.dart';
import 'package:quickgrocery/core/order/order_placement_log.dart';
import 'package:quickgrocery/core/user/checkout_preferences_store.dart';

/// Local checkout state with session persistence for payment, address, instructions.
class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController(this._ref) : super(CheckoutState.fresh()) {
    Future.microtask(_bootstrap);
  }

  final Ref _ref;
  KeepAliveLink? _keepAlive;
  bool _hydrated = false;
  bool _placementLock = false;
  int _attemptId = 0;
  int? _keyRotatedForAttempt;
  int? _closedAttemptId;

  /// Id of the placement started by the latest Place Order tap.
  int get currentAttemptId => _attemptId;

  /// True only while Razorpay is up: the tap lock is held and the overlay is hidden.
  bool get isAwaitingExternalPayment => _placementLock && !state.isPlacingOrder;

  bool get placementLocked => _placementLock;
  String? pendingPaymentId;
  String? pendingGatewayOrderId;

  /// False when [attemptId] belongs to a placement that already ended.
  bool ownsAttempt(int attemptId) => mounted && attemptId == _attemptId;

  /// Explicit cancel already ended this attempt, so a late gateway success
  /// must not place an order.
  bool isAttemptCancelled(int attemptId) => _closedAttemptId == attemptId;

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

  void _retainDuringPlacement() {
    _keepAlive ??= _ref.keepAlive();
  }

  void _releasePlacementKeepAlive() {
    _keepAlive?.close();
    _keepAlive = null;
  }

  bool _accepts(int? attemptId) {
    if (!mounted) return false;
    if (attemptId != null && attemptId != _attemptId) {
      OrderPlacementLog.staleCallbackIgnored(attemptId);
      return false;
    }
    return true;
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
    _attemptId++;
    OrderPlacementLog.bindAttempt(_attemptId);
    _placementLock = true;
    _retainDuringPlacement();
    pendingPaymentId = null;
    pendingGatewayOrderId = null;
    state = state.copyWith(isPlacingOrder: true, clearError: true);
    OrderPlacementLog.loadingStarted(idempotencyKey: state.idempotencyKey);
    return true;
  }

  /// Keep the tap lock but hide the blocking overlay so Razorpay can present.
  void beginAwaitingExternalPayment({required int attemptId}) {
    if (!_accepts(attemptId)) return;
    _placementLock = true;
    _retainDuringPlacement();
    state = state.copyWith(isPlacingOrder: false, clearError: true);
    OrderPlacementLog.dialogDismissed();
  }

  /// Show loading again after a payment callback, before order creation.
  bool resumePlacementAfterPayment({
    required int attemptId,
    String? paymentId,
    String? gatewayOrderId,
  }) {
    if (!_accepts(attemptId)) return false;
    if (_closedAttemptId == attemptId) {
      OrderPlacementLog.staleCallbackIgnored(attemptId);
      return false;
    }
    _placementLock = true;
    _retainDuringPlacement();
    if (paymentId != null && paymentId.isNotEmpty) {
      pendingPaymentId = paymentId;
    }
    if (gatewayOrderId != null && gatewayOrderId.isNotEmpty) {
      pendingGatewayOrderId = gatewayOrderId;
    }
    state = state.copyWith(isPlacingOrder: true, clearError: true);
    OrderPlacementLog.loadingStarted(idempotencyKey: state.idempotencyKey);
    return true;
  }

  /// User cancelled before an order existed. Next Place Order is a new attempt.
  ///
  /// [closePayment] rejects a later success callback for this same attempt.
  /// The resume timer leaves it false so a slow success can still place.
  void cancelPlacement({int? attemptId, bool closePayment = true}) {
    if (!_accepts(attemptId)) return;
    if (closePayment) _closedAttemptId = _attemptId;
    _stopPlacement(reason: 'cancelled', rotateKey: true);
  }

  void finishPlacementSuccess({int? attemptId}) {
    if (!_accepts(attemptId)) return;
    pendingPaymentId = null;
    pendingGatewayOrderId = null;
    // Stay locked + loading until checkout screen disposes after navigation.
    state = state.copyWith(isPlacingOrder: true, clearError: true);
  }

  /// Re-enables the button. Keeps the same idempotency key so a retry of this
  /// attempt still dedupes if the server may already have created the order.
  void finishPlacementFailure({int? attemptId}) {
    if (!_accepts(attemptId)) return;
    _stopPlacement(reason: 'failure', rotateKey: false);
  }

  /// Checkout route is gone. Drop the keep-alive so the next visit is not
  /// stuck on a previous `isPlacingOrder` flag.
  void endPlacementSession() {
    if (!mounted) return;
    _attemptId++;
    OrderPlacementLog.bindAttempt(_attemptId);
    _stopPlacement(reason: 'session_end', rotateKey: false);
  }

  void _stopPlacement({required String reason, required bool rotateKey}) {
    if (!mounted) return;
    final wasActive =
        _placementLock ||
        state.isPlacingOrder ||
        pendingPaymentId != null ||
        pendingGatewayOrderId != null;
    final rotate = rotateKey && _keyRotatedForAttempt != _attemptId;
    _placementLock = false;
    pendingPaymentId = null;
    pendingGatewayOrderId = null;
    _releasePlacementKeepAlive();
    if (state.isPlacingOrder || state.errorMessage != null || rotate) {
      state = state.copyWith(
        isPlacingOrder: false,
        clearError: true,
        rotateIdempotencyKey: rotate,
      );
      if (rotate) _keyRotatedForAttempt = _attemptId;
    }
    if (wasActive || rotate) {
      OrderPlacementLog.dialogDismissed();
      OrderPlacementLog.stateReset(rotatedKey: rotate);
      OrderPlacementLog.loadingCleared(
        reason: reason,
        idempotencyKey: state.idempotencyKey,
      );
      OrderPlacementLog.end(reason: reason);
    }
  }

  void selectAddress(int index) {
    if (!mounted || state.isPlacingOrder || _placementLock) return;
    state = state.copyWith(selectedAddressIndex: index);
    _persist();
  }

  void selectSlot(DeliverySlot slot) {
    if (!mounted || state.isPlacingOrder || _placementLock) return;
    state = state.copyWith(slot: slot);
  }

  void setInstructions(DeliveryInstructions instructions) {
    if (!mounted || state.isPlacingOrder || _placementLock) return;
    state = state.copyWith(instructions: instructions);
    _persist();
  }

  void selectPaymentMethod(PaymentMethod method) {
    if (!mounted || state.isPlacingOrder || _placementLock) return;
    state = state.copyWith(paymentMethod: method);
    _persist();
  }

  void setDeliveryTip(double amount) {
    if (!mounted || state.isPlacingOrder || _placementLock) return;
    state = state.copyWith(deliveryTipAmount: amount < 0 ? 0 : amount);
  }

  void setPlacingOrder(bool placing) {
    if (!mounted) return;
    if (placing) {
      tryBeginPlacement();
      return;
    }
    _stopPlacement(reason: 'set_placing_false', rotateKey: false);
  }

  void clearError() {
    if (!mounted) return;
    state = state.copyWith(clearError: true);
  }

  void setError(String message) {
    if (!mounted) return;
    finishPlacementFailure();
    if (!mounted) return;
    state = state.copyWith(errorMessage: message);
  }

  @override
  void dispose() {
    _keepAlive?.close();
    super.dispose();
  }
}

final checkoutControllerProvider =
    StateNotifierProvider.autoDispose<CheckoutController, CheckoutState>(
      CheckoutController.new,
    );
