import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:quickgrocery/core/order/order_placement_log.dart';

class PaymentService extends ChangeNotifier {
  bool isCashOnDelivery = false;
  String paymentStatus = "Pending";
  final Razorpay _razorpay = Razorpay();
  void Function(String paymentId, String? gatewayOrderId)?
  _onPaymentSuccessCallback;
  void Function(String message)? _onPaymentErrorCallback;

  /// Last gateway payment id after a successful callback (never a secret).
  String? lastPaymentId;

  /// Razorpay Key ID (public). Secret keys must never live in the client.
  static const _razorpayKeyId = 'rzp_live_SLDUzSlRIhWOXG';

  void resetSessionForLogout() {
    isCashOnDelivery = false;
    paymentStatus = 'Pending';
    _onPaymentSuccessCallback = null;
    _onPaymentErrorCallback = null;
    notifyListeners();
  }

  void onPaymentMethodChange(bool v) {
    isCashOnDelivery = v;
    notifyListeners();
  }

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout(
    double amount,
    String name,
    String description, {
    void Function(String paymentId, String? gatewayOrderId)? onPaymentSuccess,
    void Function(String message)? onPaymentError,
  }) {
    _onPaymentSuccessCallback = onPaymentSuccess;
    _onPaymentErrorCallback = onPaymentError;

    final paise = (amount * 100).round();
    if (paise < 100) {
      _failOpen('Payable amount is too small for online payment. Try COD.');
      return;
    }

    final contact = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final displayName = name.trim().isEmpty ? 'Quick Groceries' : name.trim();

    final options = <String, dynamic>{
      'key': _razorpayKeyId,
      'amount': paise,
      'currency': 'INR',
      'name': displayName,
      'description': description,
      'prefill': {'contact': contact, 'email': ''},
      'theme': {'color': '#FFC107'},
    };

    OrderPlacementLog.paymentInit(amountPaise: paise);
    try {
      OrderPlacementLog.paymentGatewayOpen();
      _razorpay.open(options);
    } catch (e, st) {
      debugPrint('PAYMENT_GATEWAY_OPEN failed: $e\n$st');
      _failOpen('Could not open payment. Please try again.');
    }
  }

  void _failOpen(String message) {
    paymentStatus = 'Payment Failed: $message';
    notifyListeners();
    final cb = _onPaymentErrorCallback;
    _onPaymentSuccessCallback = null;
    _onPaymentErrorCallback = null;
    cb?.call(message);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId?.trim() ?? '';
    OrderPlacementLog.paymentSuccessCallback(
      hasPaymentId: paymentId.isNotEmpty,
    );
    if (paymentId.isEmpty) {
      _failOpen(
        'Payment succeeded but no payment ID was returned. Contact support.',
      );
      return;
    }
    lastPaymentId = paymentId;
    paymentStatus = 'Payment Successful';
    notifyListeners();
    final cb = _onPaymentSuccessCallback;
    _onPaymentSuccessCallback = null;
    _onPaymentErrorCallback = null;
    OrderPlacementLog.paymentVerificationStarted(hasPaymentId: true);
    OrderPlacementLog.paymentVerificationSuccess();
    cb?.call(paymentId, response.orderId?.trim());
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    OrderPlacementLog.paymentFailureCallback(code: response.code);
    paymentStatus = 'Payment Failed: ${response.message}';
    notifyListeners();
    final code = response.code;
    final raw = response.message?.trim();
    String msg;
    if (code == Razorpay.PAYMENT_CANCELLED ||
        (raw != null && raw.toLowerCase().contains('cancel'))) {
      msg = 'Payment cancelled. Your order was not placed.';
    } else if (raw != null && raw.isNotEmpty) {
      msg = raw;
    } else {
      msg = 'Payment failed. Please try again.';
    }
    final cb = _onPaymentErrorCallback;
    _onPaymentErrorCallback = null;
    _onPaymentSuccessCallback = null;
    cb?.call(msg);
  }

  void _handleExternalWallet(ExternalWalletResponse _) {
    paymentStatus = 'External Wallet Selected';
    notifyListeners();
    OrderPlacementLog.paymentStarted(
      method: 'external_wallet',
      idempotencyKey: '',
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
