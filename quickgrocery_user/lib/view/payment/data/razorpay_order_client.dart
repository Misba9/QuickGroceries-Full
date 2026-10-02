import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/view/payment/data/razorpay_public_config.dart';
import 'package:quickgrocery/view/payment/domain/razorpay_payment_result.dart';

/// Talks to Cloud Functions for Razorpay Orders API + payment confirmation.
/// The Razorpay Key Secret never leaves the backend.
class RazorpayOrderClient {
  RazorpayOrderClient({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: _region,
            );

  static const _region = 'us-central1';
  static const createFunction = 'createRazorpayOrderCallable';
  static const confirmTipFunction = 'confirmRazorpayTipPaymentCallable';

  final FirebaseFunctions _fn;

  Future<RazorpayCheckoutSession> createGroceryOrder({
    required double amountRupees,
    String? idempotencyKey,
  }) {
    return _create(
      amountRupees: amountRupees,
      purpose: 'grocery_order',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<RazorpayCheckoutSession> createTipOrder({
    required double amountRupees,
    required String groceryOrderId,
  }) {
    return _create(
      amountRupees: amountRupees,
      purpose: 'delivery_tip',
      tipOrderId: groceryOrderId,
    );
  }

  Future<RazorpayCheckoutSession> _create({
    required double amountRupees,
    required String purpose,
    String? idempotencyKey,
    String? tipOrderId,
  }) async {
    final amountPaise = (amountRupees * 100).round();
    if (amountPaise < 100) {
      throw StateError('Amount must be at least ₹1.00.');
    }

    try {
      final res = await _fn.httpsCallable(createFunction).call({
        'amount': amountRupees,
        'amountPaise': amountPaise,
        'purpose': purpose,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
        if (tipOrderId != null && tipOrderId.isNotEmpty) 'orderId': tipOrderId,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      final keyId = (data['keyId'] ?? '').toString();
      final orderId = (data['orderId'] ?? '').toString();
      final amount = (data['amount'] as num?)?.toInt() ?? 0;
      final currency = (data['currency'] ?? 'INR').toString();
      if (keyId.isEmpty || orderId.isEmpty || amount <= 0) {
        throw StateError('Invalid Razorpay order response from server.');
      }
      return RazorpayCheckoutSession(
        keyId: keyId,
        orderId: orderId,
        amountPaise: amount,
        currency: currency,
        requiresSignature: true,
      );
    } on FirebaseFunctionsException catch (e) {
      // Function not deployed yet → open Standard Checkout with public key so
      // the user can still pay. Deploy createRazorpayOrderCallable for Orders API.
      if (_canUsePublicKeyFallback(e)) {
        if (kDebugMode) {
          debugPrint(
            'Razorpay create callable unavailable (${e.code}); '
            'using public-key Standard Checkout fallback.',
          );
        }
        final keyId = await resolveRazorpayPublicKeyId();
        return RazorpayCheckoutSession(
          keyId: keyId,
          orderId: '',
          amountPaise: amountPaise,
          currency: 'INR',
          requiresSignature: false,
        );
      }
      final code = e.code;
      final message = (e.message ?? '').trim();
      if (code == 'not-found') {
        throw StateError(
          'Payment service is not deployed yet. '
          'Deploy createRazorpayOrderCallable, or check your connection.',
        );
      }
      if (code == 'failed-precondition' || code == 'internal') {
        throw StateError(
          message.isNotEmpty
              ? message
              : 'Payment server is not configured. Set Razorpay secrets.',
        );
      }
      throw StateError(
        message.isNotEmpty
            ? message
            : 'Could not start payment ($code)',
      );
    }
  }

  bool _canUsePublicKeyFallback(FirebaseFunctionsException e) {
    return e.code == 'not-found' ||
        e.code == 'unimplemented' ||
        e.code == 'unavailable';
  }

  /// Server-side tip payment verification (signature + anti-replay).
  Future<void> confirmTipPayment({
    required String groceryOrderId,
    required RazorpayPaymentResult payment,
    required int tipDeltaRupees,
  }) async {
    try {
      await _fn.httpsCallable(confirmTipFunction).call({
        'orderId': groceryOrderId,
        'tipAmount': tipDeltaRupees,
        'razorpay_payment_id': payment.paymentId,
        'razorpay_order_id': payment.orderId,
        'razorpay_signature': payment.signature,
      });
    } on FirebaseFunctionsException catch (e) {
      throw StateError(
        e.message ?? 'Tip payment verification failed (${e.code})',
      );
    }
  }
}
