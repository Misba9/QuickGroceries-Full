import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'package:quickgrocery/core/auth/guest_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/guest_auth_guard.dart';
import 'package:quickgrocery/core/order/order_placement_log.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/delivery/delivery_zone_lookup.dart';
import 'package:quickgrocery/core/availability/availability_service.dart';
import 'package:quickgrocery/core/feedback/show_top_error_toast.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/user/checkout_preferences_store.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/domain/pricing_calculator.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/checkout_controller.dart';
import 'package:quickgrocery/view/cart/presentation/providers/delivery_slots_provider.dart';
import 'package:quickgrocery/view/cart/data/order_placement_client.dart';
import 'package:quickgrocery/view/cart/presentation/providers/order_repository_provider.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/delivery_instructions_field.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/delivery_slot_selector.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/payment_method_selector.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_checkout_bar.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_bill_card.dart';
import 'package:quickgrocery/view/checkout/widgets/address_card.dart';
import 'package:quickgrocery/view/checkout/widgets/empty_address_widget.dart';
import 'package:quickgrocery/core/device/device_id_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/checkout_coupon_section.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/checkout_tip_section.dart';
import 'package:quickgrocery/view/delivery_tips/models/delivery_tip_settings.dart';
import 'package:quickgrocery/view/delivery_tips/services/delivery_tip_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/payment/services/payment_service.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_extensions.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with WidgetsBindingObserver {
  static const _calc = PricingCalculator();
  final _tipService = deliveryTipServiceProvider;
  DeliveryTipSettings _tipSettings = DeliveryTipSettings.defaults();
  bool _tipSettingsLoaded = false;
  int? _navigatedAttemptId;
  Timer? _externalPaymentResumeTimer;

  bool _isCheckoutCurrent() {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTipSettings();
  }

  @override
  void dispose() {
    _externalPaymentResumeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ref.read(checkoutControllerProvider.notifier).endPlacementSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final checkout = ref.read(checkoutControllerProvider.notifier);
    if (!checkout.isAwaitingExternalPayment) return;
    final attemptId = checkout.currentAttemptId;
    _externalPaymentResumeTimer?.cancel();
    _externalPaymentResumeTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      final notifier = ref.read(checkoutControllerProvider.notifier);
      if (!notifier.ownsAttempt(attemptId)) {
        OrderPlacementLog.staleCallbackIgnored(attemptId);
        return;
      }
      if (!notifier.isAwaitingExternalPayment) return;
      final key = ref.read(checkoutControllerProvider).idempotencyKey;
      OrderPlacementLog.paymentCancelled(
        reason: 'external_payment_not_completed',
      );
      OrderPlacementLog.cancelled(
        reason: 'external_payment_not_completed',
        idempotencyKey: key,
      );
      notifier.cancelPlacement(attemptId: attemptId, closePayment: false);
      if (_isCheckoutCurrent()) {
        showTopErrorToast(
          context,
          'Payment was not completed. You can try again.',
        );
      }
    });
  }

  Future<void> _loadTipSettings() async {
    try {
      final s = await _tipService.fetchSettings();
      if (mounted) {
        setState(() {
          _tipSettings = s;
          _tipSettingsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _tipSettingsLoaded = true);
    }
  }

  BillBreakdown _bill(CartState cart, double zoneCharge, {double tip = 0}) {
    final deliveryInt = zoneCharge > 0
        ? zoneCharge.round()
        : cart.pricing.standardDeliveryCharge;
    return _calc
        .compute(
          items: cart.items,
          config: cart.pricing,
          coupon: cart.coupon,
          deliveryChargeOverride: deliveryInt,
        )
        .withDeliveryTip(tip);
  }

  Future<void> _openAddAddress({AddressModel? edit}) async {
    final ok = await Navigator.push<bool>(
      context,
      AppPageRoutes.addAddress(editing: edit),
    );
    if (ok == true && mounted) {
      await legacy_provider.Provider.of<AddressService>(
        context,
        listen: false,
      ).getAddress();
    }
  }

  bool _attemptStillCurrent(CheckoutController notifier, int attemptId) {
    if (!notifier.ownsAttempt(attemptId)) {
      OrderPlacementLog.staleCallbackIgnored(attemptId);
      return false;
    }
    return true;
  }

  Future<void> _placeOrder({
    required int attemptId,
    required CartState cart,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    required AddressModel address,
    required String pin,
    required LatLng coords,
    required String readableAddress,
  }) async {
    final checkoutNotifier = ref.read(checkoutControllerProvider.notifier);
    final idempotencyKey = ref.read(checkoutControllerProvider).idempotencyKey;
    final payment = legacy_provider.Provider.of<PaymentService>(
      context,
      listen: false,
    );
    var handedToGateway = false;

    try {
      OrderPlacementLog.validationStarted(idempotencyKey: idempotencyKey);
      final availability = await ref
          .read(availabilityServiceProvider)
          .check(cartItems: cart.items, address: address, pin: pin)
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              OrderPlacementLog.timeout(
                stage: 'availability',
                idempotencyKey: idempotencyKey,
              );
              throw TimeoutException(
                'Checking delivery availability timed out. Please try again.',
              );
            },
          );
      availability.debugLog();
      if (!_attemptStillCurrent(checkoutNotifier, attemptId) || !mounted) {
        return;
      }

      final availabilityError = availability.blockingReason;
      OrderPlacementLog.validationCompleted(
        idempotencyKey: idempotencyKey,
        ok: availabilityError == null,
        reason: availabilityError,
      );
      if (availabilityError != null) {
        throw StateError(availabilityError);
      }

      final zoneCharge = availability.deliveryCharge;
      final tip = ref.read(checkoutControllerProvider).deliveryTipAmount;
      final bill = _bill(cart, zoneCharge, tip: tip);

      debugPrint(
        'ORDER PAYMENT: method=${paymentMethod.id} total=${bill.total} '
        'cod=${paymentMethod == PaymentMethod.cod}',
      );

      if (paymentMethod == PaymentMethod.cod) {
        OrderPlacementLog.checkoutValidation(
          ok: true,
          method: paymentMethod.id,
        );
        await _finalizeOrder(
          attemptId: attemptId,
          cart: cart,
          bill: bill,
          address: address,
          readableAddress: readableAddress,
          coords: coords,
          slot: slot,
          instructions: instructions,
          paymentMethod: paymentMethod,
          idempotencyKey: idempotencyKey,
        );
        return;
      }

      OrderPlacementLog.finalAmount(
        total: bill.total,
        method: paymentMethod.id,
      );
      OrderPlacementLog.paymentStarted(
        method: paymentMethod.id,
        idempotencyKey: idempotencyKey,
      );
      _externalPaymentResumeTimer?.cancel();
      if (!_attemptStillCurrent(checkoutNotifier, attemptId)) return;
      handedToGateway = true;
      checkoutNotifier.beginAwaitingExternalPayment(attemptId: attemptId);
      payment.openCheckout(
        bill.total,
        address.name,
        'Quick Grocery order',
        onPaymentSuccess: (paymentId, gatewayOrderId) async {
          _externalPaymentResumeTimer?.cancel();
          if (!_attemptStillCurrent(checkoutNotifier, attemptId)) return;
          if (checkoutNotifier.isAttemptCancelled(attemptId)) {
            OrderPlacementLog.staleCallbackIgnored(attemptId);
            return;
          }
          OrderPlacementLog.paymentVerificationStarted(
            hasPaymentId: paymentId.isNotEmpty,
          );
          if (!checkoutNotifier.resumePlacementAfterPayment(
            attemptId: attemptId,
            paymentId: paymentId,
            gatewayOrderId: gatewayOrderId,
          )) {
            OrderPlacementLog.paidOrderCreateFailure(hasPaymentId: true);
            OrderPlacementLog.error(
              stage: 'payment_success_checkout_closed',
              error: 'checkout_unmounted',
              idempotencyKey: idempotencyKey,
            );
            if (_isCheckoutCurrent()) {
              _showPaidOrderRecovery(
                'Payment was received but checkout closed before the order '
                'could be created. Payment ID: $paymentId. Do not pay again — '
                'contact support with this ID.',
              );
            }
            return;
          }
          try {
            await _finalizeOrder(
              attemptId: attemptId,
              cart: cart,
              bill: bill,
              address: address,
              readableAddress: readableAddress,
              coords: coords,
              slot: slot,
              instructions: instructions,
              paymentMethod: paymentMethod,
              paymentRef: paymentId,
              razorpayOrderId: gatewayOrderId,
              idempotencyKey: idempotencyKey,
            );
          } catch (e, stack) {
            OrderPlacementLog.paidOrderCreateFailure(hasPaymentId: true);
            OrderPlacementLog.error(
              stage: 'paid_order_create',
              error: e,
              idempotencyKey: idempotencyKey,
            );
            checkoutNotifier.finishPlacementFailure(attemptId: attemptId);
            if (_isCheckoutCurrent()) {
              _showOrderError(e, stack, paidPaymentId: paymentId);
            }
          }
        },
        onPaymentError: (message) {
          _externalPaymentResumeTimer?.cancel();
          if (!_attemptStillCurrent(checkoutNotifier, attemptId)) return;
          final cancelled = message.toLowerCase().contains('cancel');
          if (cancelled) {
            OrderPlacementLog.paymentCancelled(reason: 'payment_error');
            OrderPlacementLog.cancelled(
              reason: 'payment_error',
              idempotencyKey: idempotencyKey,
            );
            checkoutNotifier.cancelPlacement(attemptId: attemptId);
          } else {
            OrderPlacementLog.apiFailed(
              idempotencyKey: idempotencyKey,
              error: message,
            );
            checkoutNotifier.finishPlacementFailure(attemptId: attemptId);
          }
          if (_isCheckoutCurrent()) {
            showTopErrorToast(
              context,
              message,
              duration: const Duration(seconds: 6),
            );
          }
        },
      );
    } catch (e, stack) {
      OrderPlacementLog.error(
        stage: 'place_order',
        error: e,
        idempotencyKey: idempotencyKey,
      );
      checkoutNotifier.finishPlacementFailure(attemptId: attemptId);
      if (_isCheckoutCurrent()) _showOrderError(e, stack);
    } finally {
      // Gateway and success navigation own the lock. A cancelled or failed
      // attempt must release it. Never pop Checkout, and never clear a newer
      // attempt that already replaced this one.
      if (!checkoutNotifier.ownsAttempt(attemptId)) {
        OrderPlacementLog.staleCallbackIgnored(attemptId);
      } else if (mounted &&
          !handedToGateway &&
          _navigatedAttemptId != attemptId) {
        final stillPlacing =
            ref.read(checkoutControllerProvider).isPlacingOrder ||
            checkoutNotifier.placementLocked;
        if (stillPlacing) {
          checkoutNotifier.finishPlacementFailure(attemptId: attemptId);
        }
      }
    }
  }

  Future<void> _finalizeOrder({
    required int attemptId,
    required CartState cart,
    required BillBreakdown bill,
    required AddressModel address,
    required String readableAddress,
    required LatLng coords,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    required String idempotencyKey,
    String? paymentRef,
    String? razorpayOrderId,
  }) async {
    final checkoutNotifier = ref.read(checkoutControllerProvider.notifier);
    if (!_attemptStillCurrent(checkoutNotifier, attemptId)) return;
    if (checkoutNotifier.isAttemptCancelled(attemptId)) {
      OrderPlacementLog.staleCallbackIgnored(attemptId);
      return;
    }
    if (_navigatedAttemptId == attemptId) {
      OrderPlacementLog.navigationBlocked(reason: 'already_navigated');
      return;
    }

    if (paymentMethod.isOnline &&
        (paymentRef == null || paymentRef.trim().isEmpty)) {
      throw StateError(
        'Online payment was not confirmed. Your order was not placed.',
      );
    }

    OrderPlacementLog.apiStarted(idempotencyKey: idempotencyKey);

    final cartNotifier = ref.read(cartProvider.notifier);

    OrderPlacementLog.orderCreateStart(idempotencyKey: idempotencyKey);
    try {
      final orderId = await _createOrderWithFallback(
        cart: cart,
        bill: bill,
        address: address,
        readableAddress: readableAddress,
        coords: coords,
        slot: slot,
        instructions: instructions,
        paymentMethod: paymentMethod,
        paymentRef: paymentRef,
        razorpayOrderId: razorpayOrderId,
        idempotencyKey: idempotencyKey,
      );
      OrderPlacementLog.apiCompleted(
        idempotencyKey: idempotencyKey,
        orderId: orderId,
      );

      if (cart.coupon != null) {
        try {
          final deviceId = await DeviceIdService.getOrCreate().timeout(
            const Duration(seconds: 5),
          );
          await ref
              .read(couponValidationClientProvider)
              .redeem(
                code: cart.coupon!.code,
                orderId: orderId,
                subtotal: bill.subtotal,
                discountApplied: bill.couponDiscount,
                items: cart.items,
                phone: address.mobile,
                deviceId: deviceId,
              )
              .timeout(const Duration(seconds: 10));
        } catch (e, stack) {
          debugPrint('COUPON REDEEM ERROR: $e');
          debugPrintStack(stackTrace: stack);
          if (e is TimeoutException) {
            OrderPlacementLog.timeout(
              stage: 'coupon_redeem',
              idempotencyKey: idempotencyKey,
            );
          }
        }
      }

      try {
        await CheckoutPreferencesStore.recordSuccessfulOrder(
          orderId: orderId,
          state: ref.read(checkoutControllerProvider),
        ).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        OrderPlacementLog.timeout(
          stage: 'checkout_preferences',
          idempotencyKey: idempotencyKey,
        );
      } catch (e, stack) {
        debugPrint('CHECKOUT PREFS SAVE ERROR: $e');
        debugPrintStack(stackTrace: stack);
      }

      try {
        await cartNotifier.clear().timeout(const Duration(seconds: 10));
      } on TimeoutException {
        OrderPlacementLog.timeout(
          stage: 'cart_clear',
          idempotencyKey: idempotencyKey,
        );
      }
      OrderPlacementLog.cartCleared(orderId: orderId);
      if (!_attemptStillCurrent(checkoutNotifier, attemptId)) return;
      checkoutNotifier.finishPlacementSuccess(attemptId: attemptId);

      if (_navigatedAttemptId == attemptId || !mounted) {
        OrderPlacementLog.navigationBlocked(
          reason: _navigatedAttemptId == attemptId
              ? 'already_navigated'
              : 'unmounted',
        );
        checkoutNotifier.finishPlacementFailure(attemptId: attemptId);
        return;
      }
      _navigatedAttemptId = attemptId;
      OrderPlacementLog.orderConfirmation(orderId: orderId);
      OrderPlacementLog.navigationStarted(orderId: orderId);
      if (!_isCheckoutCurrent()) {
        OrderPlacementLog.navigationBlocked(reason: 'route_not_current');
        checkoutNotifier.finishPlacementFailure(attemptId: attemptId);
        _navigatedAttemptId = null;
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoutes.checkoutSuccess(orderId: orderId),
        (_) => false,
      );
      OrderPlacementLog.navigationCompleted(orderId: orderId);
    } catch (e, stack) {
      OrderPlacementLog.apiFailed(idempotencyKey: idempotencyKey, error: e);
      Error.throwWithStackTrace(e, stack);
    }
  }

  void _showOrderError(Object e, StackTrace stack, {String? paidPaymentId}) {
    debugPrint('ORDER ERROR: $e');
    debugPrintStack(stackTrace: stack);
    String checkoutError(Object error) {
      if (error is FirebaseFunctionsException) {
        if (error.code == 'not-found') {
          return 'Order service unavailable. Please try again.';
        }
        if (error.code == 'unavailable') {
          return 'Order service is temporarily unavailable.';
        }
        final serverMessage = error.message?.trim();
        if (serverMessage != null && serverMessage.isNotEmpty) {
          return serverMessage;
        }
        return 'Failed to create order (${error.code})';
      }
      if (error is TimeoutException) {
        final raw = error.message?.trim();
        if (raw != null && raw.isNotEmpty) return raw;
        return 'Placing your order took too long. Please try again. '
            'If you were charged, do not pay again.';
      }
      if (error is FirebaseException) {
        debugPrint(
          'ORDER FIREBASE ERROR code=${error.code} '
          'message=${error.message} plugin=${error.plugin}',
        );
        if (error.code == 'not-found') {
          return 'Required order data was not found.';
        }
        if (error.code == 'permission-denied') {
          return 'Permission denied while creating order.';
        }
        return error.message ?? 'Failed to create order (${error.code})';
      }
      return error.toString().replaceFirst('Bad state: ', '');
    }

    if (!mounted) return;
    final message = checkoutError(e);
    if (paidPaymentId != null && paidPaymentId.isNotEmpty) {
      _showPaidOrderRecovery(
        '$message Your payment ID is $paidPaymentId. '
        'Do not pay again. If the order does not appear, contact support '
        'with this payment ID.',
      );
      return;
    }
    showTopErrorToast(context, message, duration: const Duration(seconds: 6));
  }

  void _showPaidOrderRecovery(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Payment received'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _createOrderWithFallback({
    required CartState cart,
    required BillBreakdown bill,
    required AddressModel address,
    required String readableAddress,
    required LatLng coords,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    String? paymentRef,
    String? razorpayOrderId,
    String? idempotencyKey,
  }) async {
    final client = ref.read(orderPlacementClientProvider);
    final repo = ref.read(orderRepositoryProvider);
    final key = idempotencyKey ?? '';

    Future<String> callCallable() => client.placeOrder(
      items: cart.items,
      coupon: cart.coupon,
      bill: bill,
      address: address,
      currentAddressString: readableAddress,
      currentLatLng: coords,
      slot: slot,
      instructions: instructions,
      paymentMethod: paymentMethod,
      paymentRef: paymentRef,
      razorpayOrderId: razorpayOrderId,
      tipAmount: bill.deliveryPartnerTip,
      idempotencyKey: key,
    );

    try {
      return await callCallable();
    } on FirebaseFunctionsException catch (e, stack) {
      debugPrint(
        'ORDER CALLABLE FAILED code=${e.code} message=${e.message} '
        'details=${e.details}',
      );
      debugPrintStack(stackTrace: stack);

      if (paymentRef != null && paymentRef.trim().isNotEmpty) {
        final byPay = await repo.findOrderByPaymentRef(paymentRef);
        if (byPay != null) {
          OrderPlacementLog.duplicateDetected(
            idempotencyKey: key,
            orderId: byPay,
          );
          OrderPlacementLog.apiCompleted(
            idempotencyKey: key,
            orderId: byPay,
            duplicate: true,
          );
          return byPay;
        }
      }

      if (key.isNotEmpty) {
        final existing = await repo.findExistingOrderId(
          idempotencyKey: key,
          waitForPending: OrderPlacementClient.isTransientFunctionsError(e),
        );
        if (existing != null) {
          OrderPlacementLog.duplicateDetected(
            idempotencyKey: key,
            orderId: existing,
          );
          OrderPlacementLog.apiCompleted(
            idempotencyKey: key,
            orderId: existing,
            duplicate: true,
          );
          return existing;
        }
      }

      if (e.code == 'deadline-exceeded') {
        OrderPlacementLog.timeout(
          stage: 'place_order_callable',
          idempotencyKey: key,
        );
      }

      if (OrderPlacementClient.isPermanentFunctionsError(e)) {
        rethrow;
      }

      if (OrderPlacementClient.isTransientFunctionsError(e)) {
        try {
          return await callCallable();
        } on FirebaseFunctionsException catch (retryError, retryStack) {
          debugPrint(
            'ORDER CALLABLE RETRY FAILED code=${retryError.code} '
            'message=${retryError.message}',
          );
          debugPrintStack(stackTrace: retryStack);
          if (key.isNotEmpty) {
            final existing = await repo.findExistingOrderId(
              idempotencyKey: key,
              waitForPending: OrderPlacementClient.isTransientFunctionsError(
                retryError,
              ),
            );
            if (existing != null) {
              OrderPlacementLog.duplicateDetected(
                idempotencyKey: key,
                orderId: existing,
              );
              OrderPlacementLog.apiCompleted(
                idempotencyKey: key,
                orderId: existing,
                duplicate: true,
              );
              return existing;
            }
          }
          if (!_canFallbackToDirectOrder(retryError)) rethrow;
        }
      } else if (!_canFallbackToDirectOrder(e)) {
        rethrow;
      }

      if (key.isNotEmpty) {
        final existing = await repo.findExistingOrderId(idempotencyKey: key);
        if (existing != null) {
          OrderPlacementLog.duplicateDetected(
            idempotencyKey: key,
            orderId: existing,
          );
          OrderPlacementLog.apiCompleted(
            idempotencyKey: key,
            orderId: existing,
            duplicate: true,
          );
          return existing;
        }
      }

      return _createDirectFirestoreOrder(
        cart: cart,
        bill: bill,
        address: address,
        readableAddress: readableAddress,
        coords: coords,
        slot: slot,
        instructions: instructions,
        paymentMethod: paymentMethod,
        paymentRef: paymentRef,
        idempotencyKey: key,
      );
    }
  }

  bool _canFallbackToDirectOrder(FirebaseFunctionsException e) {
    return e.code == 'not-found' || e.code == 'unavailable';
  }

  Future<String> _createDirectFirestoreOrder({
    required CartState cart,
    required BillBreakdown bill,
    required AddressModel address,
    required String readableAddress,
    required LatLng coords,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    String? paymentRef,
    String? idempotencyKey,
  }) async {
    debugPrint(
      'ORDER FALLBACK: creating direct Firestore order path=orders '
      'reason=callable_unavailable',
    );
    try {
      final orderId = await ref
          .read(orderRepositoryProvider)
          .placeOrder(
            items: cart.items,
            coupon: cart.coupon,
            bill: bill,
            address: address,
            currentAddressString: readableAddress,
            currentLatLng: coords,
            slot: slot,
            instructions: instructions,
            paymentMethod: paymentMethod,
            paymentRef: paymentRef,
            idempotencyKey: idempotencyKey,
          )
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () {
              OrderPlacementLog.timeout(
                stage: 'firestore_order',
                idempotencyKey: idempotencyKey ?? '',
              );
              throw TimeoutException(
                'Creating the order timed out. Please try again.',
              );
            },
          );
      debugPrint('ORDER FALLBACK SUCCESS firestorePath=orders/$orderId');
      return orderId;
    } on TimeoutException {
      final key = idempotencyKey ?? '';
      if (key.isNotEmpty) {
        final existing = await ref
            .read(orderRepositoryProvider)
            .findExistingOrderId(
              idempotencyKey: key,
              timeout: const Duration(seconds: 8),
            );
        if (existing != null) {
          OrderPlacementLog.duplicateDetected(
            idempotencyKey: key,
            orderId: existing,
          );
          return existing;
        }
      }
      rethrow;
    } on FirebaseException catch (e, stack) {
      debugPrint(
        'ORDER FALLBACK FIRESTORE ERROR path=orders '
        'code=${e.code} message=${e.message}',
      );
      debugPrintStack(stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      debugPrint('ORDER FALLBACK ERROR path=orders error=$e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final checkoutNotifier = ref.read(checkoutControllerProvider.notifier);

    final slots = ref.watch(deliverySlotsProvider);

    final addressService = legacy_provider.Provider.of<AddressService>(context);
    final home = legacy_provider.Provider.of<HomeProvider>(
      context,
      listen: false,
    );

    ref.listen<String?>(
      checkoutControllerProvider.select((s) => s.errorMessage),
      (_, msg) {
        if (msg != null) {
          showTopErrorToast(context, msg);
          ref.read(checkoutControllerProvider.notifier).clearError();
        }
      },
    );

    final addresses = addressService.addresses ?? const <AddressModel>[];
    final preferredIndex = addressService.hasValidatedServiceableAddress
        ? addressService.selectedIndex
        : checkout.selectedAddressIndex;
    final idx = preferredIndex.clamp(
      0,
      addresses.isEmpty ? 0 : addresses.length - 1,
    );
    final selectedAddr = addresses.isEmpty ? null : addresses[idx];
    final authPhone = FirebaseAuth.instance.currentUser?.phoneNumber;
    final addrComplete =
        selectedAddr?.isCompleteForDelivery(authPhone) ?? false;

    final pin = DeliveryZoneLookup.normalizePin(
      addressService.activeDeliveryPin ?? addressService.pinCode ?? '',
    );
    final coords = addressService.latLng ?? home.currentLatLng;
    final readable = addressService.address;
    final zoneAsync = ref.watch(zoneDeliveryProvider(pin));
    final zoneCharge = zoneAsync.value ?? 0;
    final bill = _bill(cart, zoneCharge, tip: checkout.deliveryTipAmount);

    final hasAddr = addresses.isNotEmpty && selectedAddr != null;
    final oos = cart.items.any((e) => e.isUnavailable);
    final canPay =
        hasAddr &&
        addrComplete &&
        bill.meetsMinimumOrder &&
        !oos &&
        checkout.slot != null;

    String? barHint() {
      if (!hasAddr) return context.l10n.please_add_address;
      if (!addrComplete) return context.l10n.completeAddressDetails;
      if (oos) return 'Some items are out of stock';
      if (!bill.meetsMinimumOrder) {
        final delta = (bill.minimumOrderValue - bill.subtotal).clamp(
          0,
          double.infinity,
        );
        return 'Min order ₹${bill.minimumOrderValue.toStringAsFixed(0)} · '
            'Add ₹${delta.toStringAsFixed(0)} more';
      }
      if (checkout.slot == null) return 'Choose a delivery slot';
      return null;
    }

    return PopScope(
      canPop: !checkout.isPlacingOrder,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppSurface.background,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CheckoutHeader(
                    onBack: checkout.isPlacingOrder
                        ? null
                        : () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: addresses.isEmpty
                        ? EmptyAddressWidget(
                            onAddAddress: () => _openAddAddress(),
                          )
                        : RefreshIndicator(
                            color: AppColor.primary,
                            onRefresh: () => addressService.getAddress(),
                            child: CustomScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    8,
                                    14,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: FadeInDown(
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      child: _DeliverToSection(
                                        addresses: addresses,
                                        selectedIndex: idx,
                                        onSelect: checkout.isPlacingOrder
                                            ? (_) {}
                                            : (i) {
                                                checkoutNotifier.selectAddress(
                                                  i,
                                                );
                                                addressService.selectAddress(i);
                                              },
                                        onAdd: checkout.isPlacingOrder
                                            ? () {}
                                            : () => _openAddAddress(),
                                        onEdit: checkout.isPlacingOrder
                                            ? (_) {}
                                            : (a) => _openAddAddress(edit: a),
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    16,
                                    14,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: FadeInDown(
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      child: _DeliveryEtaCard(
                                        slot:
                                            checkout.slot ?? slots.firstOrNull,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: FadeInUp(
                                      delay: const Duration(milliseconds: 80),
                                      child: CheckoutCouponSection(
                                        checkoutPhone: selectedAddr?.mobile,
                                        deliveryChargeOverride: zoneCharge > 0
                                            ? zoneCharge.round()
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    16,
                                    14,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: DeliveryInstructionsField(
                                      value: checkout.instructions,
                                      onChanged: checkout.isPlacingOrder
                                          ? (_) {}
                                          : checkoutNotifier.setInstructions,
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    18,
                                    14,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: DeliverySlotSelector(
                                      slots: slots,
                                      selected: checkout.slot,
                                      onChanged: checkout.isPlacingOrder
                                          ? (_) {}
                                          : checkoutNotifier.selectSlot,
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    18,
                                    14,
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: PaymentMethodSelector(
                                      selected: checkout.paymentMethod,
                                      onChanged: checkout.isPlacingOrder
                                          ? (_) {}
                                          : checkoutNotifier
                                                .selectPaymentMethod,
                                    ),
                                  ),
                                ),
                                if (zoneAsync.isLoading && zoneCharge == 0)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        14,
                                        12,
                                        14,
                                        0,
                                      ),
                                      child: LinearProgressIndicator(
                                        minHeight: 2,
                                        backgroundColor: AppSurface.subtle,
                                      ),
                                    ),
                                  ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    18,
                                    14,
                                    24,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _CheckoutDeliveryInfo(
                                          bill: bill,
                                          pricing: cart.pricing,
                                        ),
                                        const SizedBox(height: 10),
                                        if (_tipSettingsLoaded &&
                                            _tipSettings.enabled) ...[
                                          CheckoutTipSection(
                                            settings: _tipSettings,
                                            selectedAmount:
                                                checkout.deliveryTipAmount,
                                            onChanged: checkout.isPlacingOrder
                                                ? (_) {}
                                                : checkoutNotifier
                                                      .setDeliveryTip,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        PremiumBillCard(
                                          bill: bill,
                                          pricing: cart.pricing,
                                          couponLabel: cart.coupon != null
                                              ? 'Coupon · ${cart.coupon!.code}'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: hasAddr
                ? StickyCheckoutBar(
                    totalAmount: bill.total,
                    itemCount: cart.totalUnits,
                    savings: bill.totalSavings,
                    buttonText: 'Place Order',
                    loadingLabel: 'Placing your order...',
                    helperText: barHint(),
                    helperIsError:
                        !hasAddr ||
                        !addrComplete ||
                        oos ||
                        !bill.meetsMinimumOrder ||
                        checkout.slot == null,
                    enabled: canPay,
                    isLoading: checkout.isPlacingOrder,
                    onTap: () async {
                      final checkoutNotifier = ref.read(
                        checkoutControllerProvider.notifier,
                      );
                      if (!checkoutNotifier.tryBeginPlacement()) return;
                      final attemptId = checkoutNotifier.currentAttemptId;
                      _externalPaymentResumeTimer?.cancel();
                      final idempotencyKey = ref
                          .read(checkoutControllerProvider)
                          .idempotencyKey;
                      OrderPlacementLog.started(idempotencyKey: idempotencyKey);
                      OrderPlacementLog.buttonTapped(
                        idempotencyKey: idempotencyKey,
                      );

                      try {
                        if (!bill.meetsMinimumOrder ||
                            oos ||
                            checkout.slot == null ||
                            !addrComplete) {
                          checkoutNotifier.cancelPlacement(
                            attemptId: attemptId,
                          );
                          if (!addrComplete) {
                            await _openAddAddress(edit: selectedAddr);
                          }
                          return;
                        }

                        final authed = await GuestAuthGuard.requireAuth(
                          context,
                          ref,
                          postLogin: GuestPostLoginAction.continueCheckout,
                        );
                        if (!authed || !mounted) {
                          checkoutNotifier.cancelPlacement(
                            attemptId: attemptId,
                          );
                          return;
                        }
                        if (!_attemptStillCurrent(
                          checkoutNotifier,
                          attemptId,
                        )) {
                          return;
                        }

                        await _placeOrder(
                          attemptId: attemptId,
                          cart: cart,
                          slot: checkout.slot,
                          instructions: checkout.instructions,
                          paymentMethod: checkout.paymentMethod,
                          address: selectedAddr,
                          pin: pin,
                          coords: coords,
                          readableAddress: readable,
                        );
                      } catch (e, stack) {
                        if (checkoutNotifier.ownsAttempt(attemptId)) {
                          checkoutNotifier.finishPlacementFailure(
                            attemptId: attemptId,
                          );
                        }
                        OrderPlacementLog.error(
                          stage: 'place_order_tap',
                          error: e,
                          idempotencyKey: idempotencyKey,
                        );
                        debugPrintStack(stackTrace: stack);
                        if (!context.mounted) return;
                        final route = ModalRoute.of(context);
                        if (route != null && !route.isCurrent) return;
                        showTopErrorToast(
                          context,
                          'Could not start your order. Please try again.',
                        );
                      }
                    },
                  )
                : StickyCheckoutBar(
                    totalAmount: bill.total,
                    itemCount: cart.totalUnits,
                    savings: bill.totalSavings,
                    buttonText: 'Add Address',
                    loadingLabel: 'Placing your order...',
                    helperText: barHint(),
                    helperIsError: true,
                    enabled: !checkout.isPlacingOrder,
                    isLoading: checkout.isPlacingOrder,
                    onTap: checkout.isPlacingOrder
                        ? () {}
                        : () => _openAddAddress(),
                  ),
          ),
          if (checkout.isPlacingOrder)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.08),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadow.dim,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Text(
                              'Please wait, we\'re placing your order...',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: AppSurface.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckoutDeliveryInfo extends StatelessWidget {
  const _CheckoutDeliveryInfo({required this.bill, required this.pricing});

  final BillBreakdown bill;
  final PricingConfig pricing;

  @override
  Widget build(BuildContext context) {
    final msg = !pricing.isDeliveryChargesEnabled
        ? 'Delivery charges are currently disabled'
        : bill.isFreeDelivery
        ? '🎉 FREE delivery unlocked'
        : pricing.isFreeDeliveryEnabled
        ? 'Free delivery above ₹${pricing.freeDeliveryThreshold}'
        : 'Delivery fee ₹${bill.deliveryFee.toStringAsFixed(0)} applies';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppSurface.border),
      ),
      child: Text(
        msg,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppSurface.textSecondary,
        ),
      ),
    );
  }
}

extension _SlotListX on List<DeliverySlot> {
  DeliverySlot? get firstOrNull => isEmpty ? null : first;
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: AppShadow.dim),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onBack!();
                  },
          ),
          Expanded(
            child: Text(
              context.l10n.checkout,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppSurface.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverToSection extends StatelessWidget {
  const _DeliverToSection({
    required this.addresses,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
  });

  final List<AddressModel> addresses;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<AddressModel> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_rounded, size: 18, color: AppSurface.text),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deliver to',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppSurface.text,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                context.l10n.add_address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(addresses.length, (i) {
          final a = addresses[i];
          return FadeInUp(
            duration: Duration(milliseconds: 260 + i * 40),
            child: CheckoutAddressCard(
              heroTag: 'checkout-addr-$i-${a.id}',
              address: a,
              selected: i == selectedIndex,
              onSelect: () => onSelect(i),
              onEdit: () => onEdit(a),
            ),
          );
        }),
      ],
    );
  }
}

class _DeliveryEtaCard extends ConsumerWidget {
  const _DeliveryEtaCard({required this.slot});

  final DeliverySlot? slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryEta = ref.appContent.deliveryTimeText;
    return _MiniCard(
      icon: Icons.schedule_rounded,
      iconColor: AppSurface.success,
      title: context.l10n.delivery_eta_title,
      subtitle: slot != null ? '$deliveryEta · ${slot!.label}' : deliveryEta,
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.dim,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppSurface.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.4,
              color: AppSurface.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
