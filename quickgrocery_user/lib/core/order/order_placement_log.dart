import 'package:flutter/foundation.dart';

/// Structured checkout / order placement logs (debug & release logcat).
abstract final class OrderPlacementLog {
  static int? activeAttempt;

  static void bindAttempt(int attemptId) {
    activeAttempt = attemptId;
  }

  static void started({required String idempotencyKey}) {
    _log('START', 'key=$idempotencyKey');
  }

  static void buttonTapped({required String idempotencyKey}) {
    _log('button_tapped', 'key=$idempotencyKey');
  }

  static void duplicateTapIgnored({required String idempotencyKey}) {
    _log('duplicate_tap_ignored', 'key=$idempotencyKey');
  }

  static void loadingStarted({required String idempotencyKey}) {
    _log('LOADING=true', 'key=$idempotencyKey loading=true');
  }

  static void loadingCleared({required String reason, String? idempotencyKey}) {
    _log(
      'loading_false',
      'reason=$reason key=${idempotencyKey ?? ''} loading=false',
    );
  }

  static void validationStarted({required String idempotencyKey}) {
    _log('validation_started', 'key=$idempotencyKey');
  }

  static void validationCompleted({
    required String idempotencyKey,
    required bool ok,
    String? reason,
  }) {
    _log(
      'validation_completed',
      'key=$idempotencyKey ok=$ok reason=${reason ?? ''}',
    );
  }

  static void paymentStarted({
    required String method,
    required String idempotencyKey,
  }) {
    _log('PAYMENT_STARTED', 'method=$method key=$idempotencyKey');
  }

  static void paymentCancelled({required String reason}) {
    _log('PAYMENT_CANCELLED', reason);
  }

  static void dialogDismissed() {
    _log('DIALOG_DISMISSED', 'placement_overlay');
  }

  static void stateReset({required bool rotatedKey}) {
    _log('STATE_RESET', 'rotatedKey=$rotatedKey');
  }

  static void end({required String reason}) {
    _log('END', reason);
  }

  static void staleCallbackIgnored(int attemptId) {
    debugPrint('[OrderPlacement][attempt=$attemptId] STALE_CALLBACK_IGNORED');
  }

  static void timeout({required String stage, required String idempotencyKey}) {
    _log('timeout', 'stage=$stage key=$idempotencyKey');
  }

  static void duplicateDetected({
    required String idempotencyKey,
    required String orderId,
  }) {
    _log('duplicate_detected', 'key=$idempotencyKey orderId=$orderId');
  }

  static void cancelled({
    required String reason,
    required String idempotencyKey,
  }) {
    _log('CANCELLED', 'reason=$reason key=$idempotencyKey');
  }

  static void error({
    required String stage,
    required Object error,
    String? idempotencyKey,
  }) {
    _log('ERROR', 'stage=$stage key=${idempotencyKey ?? ''} error=$error');
  }

  static void apiStarted({required String idempotencyKey, String? path}) {
    _log('api_started', 'key=$idempotencyKey path=${path ?? 'callable'}');
  }

  static void apiCompleted({
    required String idempotencyKey,
    required String orderId,
    bool duplicate = false,
  }) {
    _log(
      'api_completed',
      'key=$idempotencyKey orderId=$orderId duplicate=$duplicate',
    );
  }

  static void apiFailed({
    required String idempotencyKey,
    required Object error,
  }) {
    _log('api_failed', 'key=$idempotencyKey error=$error');
  }

  static void navigationStarted({required String orderId}) {
    _log('navigation_started', 'orderId=$orderId');
  }

  static void navigationCompleted({required String orderId}) {
    _log('navigation_completed', 'orderId=$orderId');
  }

  static void navigationBlocked({required String reason}) {
    _log('navigation_blocked', reason);
  }

  static void paymentInit({required int amountPaise}) {
    _log('PAYMENT_INIT', 'amountPaise=$amountPaise');
  }

  static void paymentGatewayOpen() {
    _log('PAYMENT_GATEWAY_OPEN', 'razorpay');
  }

  static void paymentSuccessCallback({required bool hasPaymentId}) {
    _log('PAYMENT_SUCCESS_CALLBACK', 'hasPaymentId=$hasPaymentId');
  }

  static void paymentFailureCallback({int? code}) {
    _log('PAYMENT_FAILURE_CALLBACK', 'code=$code');
  }

  static void paymentVerificationStarted({required bool hasPaymentId}) {
    _log('PAYMENT_VERIFICATION_STARTED', 'hasPaymentId=$hasPaymentId');
  }

  static void paymentVerificationSuccess() {
    _log('PAYMENT_VERIFICATION_SUCCESS', 'callback_ids_present');
  }

  static void paymentVerificationFailure({required String reason}) {
    _log('PAYMENT_VERIFICATION_FAILURE', reason);
  }

  static void authRefreshRetry({required String code}) {
    _log('AUTH_REFRESH_RETRY', 'code=$code');
  }

  static void paidOrderCreateFailure({required bool hasPaymentId}) {
    _log('PAID_ORDER_CREATE_FAILURE', 'hasPaymentId=$hasPaymentId');
  }

  static void checkoutValidation({required bool ok, required String method}) {
    _log('CHECKOUT_VALIDATION', 'ok=$ok method=$method');
  }

  static void finalAmount({required double total, required String method}) {
    _log('FINAL_AMOUNT', 'total=$total method=$method');
  }

  static void orderCreateStart({required String idempotencyKey}) {
    _log('ORDER_CREATE_START', 'key=$idempotencyKey');
  }

  static void orderConfirmation({required String orderId}) {
    _log('ORDER_CONFIRMATION', 'orderId=$orderId');
  }

  static void cartCleared({required String orderId}) {
    _log('CART_CLEAR', 'orderId=$orderId');
  }

  static void _log(String event, String detail) {
    final attempt = activeAttempt;
    final prefix = attempt == null
        ? '[OrderPlacement]'
        : '[OrderPlacement][attempt=$attempt]';
    debugPrint('$prefix $event | $detail');
  }
}
