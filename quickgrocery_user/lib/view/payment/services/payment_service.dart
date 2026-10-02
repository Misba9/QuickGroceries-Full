import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:quickgrocery/view/payment/domain/razorpay_payment_result.dart';

class PaymentService extends ChangeNotifier {
  bool isCashOnDelivery = false;
  String paymentStatus = 'Pending';
  final Razorpay _razorpay = Razorpay();
  void Function(RazorpayPaymentResult result)? _onPaymentSuccessCallback;
  void Function(String message)? _onPaymentErrorCallback;
  bool _checkoutInFlight = false;
  bool _requiresSignature = true;

  void resetSessionForLogout() {
    isCashOnDelivery = false;
    paymentStatus = 'Pending';
    _onPaymentSuccessCallback = null;
    _onPaymentErrorCallback = null;
    _checkoutInFlight = false;
    _requiresSignature = true;
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

  /// Opens Razorpay Checkout for a checkout [session].
  ///
  /// Prefer sessions from [RazorpayOrderClient] (server Order + signature).
  /// Public-key fallback sessions omit `order_id`.
  void openCheckoutSession({
    required RazorpayCheckoutSession session,
    required String name,
    required String description,
    void Function(RazorpayPaymentResult result)? onPaymentSuccess,
    void Function(String message)? onPaymentError,
  }) {
    if (_checkoutInFlight) {
      onPaymentError?.call('Payment already in progress. Please wait.');
      return;
    }
    if (session.keyId.isEmpty || session.amountPaise < 100) {
      onPaymentError?.call('Invalid payment session. Please try again.');
      return;
    }

    _checkoutInFlight = true;
    _requiresSignature = session.requiresSignature;
    _onPaymentSuccessCallback = onPaymentSuccess;
    _onPaymentErrorCallback = onPaymentError;

    final options = <String, dynamic>{
      'key': session.keyId,
      'amount': session.amountPaise,
      'currency': session.currency,
      'name': name,
      'description': description,
      if (session.hasServerOrder) 'order_id': session.orderId,
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'email': '',
      },
      'theme': {
        'color': '#11A04C',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _checkoutInFlight = false;
      _onPaymentSuccessCallback = null;
      _onPaymentErrorCallback = null;
      if (kDebugMode) debugPrint('Razorpay open error: $e');
      onPaymentError?.call('Could not open payment. Please try again.');
    }
  }

  @Deprecated('Use openCheckoutSession with a server-created Razorpay order')
  void openCheckout(
    double amount,
    String name,
    String description, {
    void Function(String paymentId)? onPaymentSuccess,
    void Function(String message)? onPaymentError,
  }) {
    onPaymentError?.call(
      'Secure payment setup required. Please update the app and try again.',
    );
    if (kDebugMode) {
      debugPrint(
        'Blocked insecure Razorpay openCheckout(amount=$amount) without order_id',
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _checkoutInFlight = false;
    paymentStatus = 'Payment Successful';
    notifyListeners();

    final result = RazorpayPaymentResult(
      paymentId: response.paymentId?.trim() ?? '',
      orderId: response.orderId?.trim() ?? '',
      signature: response.signature?.trim() ?? '',
    );

    final successCb = _onPaymentSuccessCallback;
    final errorCb = _onPaymentErrorCallback;
    final needsSignature = _requiresSignature;
    _onPaymentSuccessCallback = null;
    _onPaymentErrorCallback = null;
    _requiresSignature = true;

    if (!result.hasPaymentId) {
      errorCb?.call('Incomplete payment response from Razorpay.');
      return;
    }
    if (needsSignature && !result.isComplete) {
      errorCb?.call('Incomplete payment response from Razorpay.');
      return;
    }
    successCb?.call(result);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _checkoutInFlight = false;
    paymentStatus = 'Payment Failed: ${response.message}';
    notifyListeners();
    final code = response.code;
    final raw = response.message?.trim() ?? '';
    String msg;
    if (code == Razorpay.PAYMENT_CANCELLED) {
      msg = 'Payment cancelled.';
    } else if (raw.isNotEmpty) {
      msg = raw;
    } else {
      msg = 'Payment failed. Please try again.';
    }
    final cb = _onPaymentErrorCallback;
    _onPaymentErrorCallback = null;
    _onPaymentSuccessCallback = null;
    _requiresSignature = true;
    cb?.call(msg);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    paymentStatus = 'External Wallet Selected';
    notifyListeners();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
