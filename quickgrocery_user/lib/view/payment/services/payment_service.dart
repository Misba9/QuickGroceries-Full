import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService extends ChangeNotifier {
  bool isCashOnDelivery = false;
  String paymentStatus = "Pending";
  Razorpay _razorpay = Razorpay();
  void Function(String paymentId)? _onPaymentSuccessCallback;
  void Function(String message)? _onPaymentErrorCallback;

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
    void Function(String paymentId)? onPaymentSuccess,
    void Function(String message)? onPaymentError,
  }) {
    _onPaymentSuccessCallback = onPaymentSuccess;
    _onPaymentErrorCallback = onPaymentError;
    var options = {
      'key': 'rzp_live_SLDUzSlRIhWOXG',
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber,
        'email': '',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    paymentStatus = "Payment Successful";
    notifyListeners();
    // Execute the callback if provided
    _onPaymentSuccessCallback?.call(response.paymentId ?? '');
    _onPaymentSuccessCallback = null;
    _onPaymentErrorCallback = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    paymentStatus = "Payment Failed: ${response.message}";
    notifyListeners();
    final msg = response.message ?? 'Payment failed';
    _onPaymentErrorCallback?.call(msg);
    _onPaymentErrorCallback = null;
    _onPaymentSuccessCallback = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    paymentStatus = "External Wallet Selected";
    notifyListeners();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
