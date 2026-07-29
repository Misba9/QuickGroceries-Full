/// Result returned by Razorpay Checkout after a successful payment.
class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;

  /// Full Orders-API triad (preferred / production).
  bool get isComplete =>
      paymentId.isNotEmpty && orderId.isNotEmpty && signature.isNotEmpty;

  /// Enough to open a paid flow when server Orders API is unavailable.
  bool get hasPaymentId => paymentId.isNotEmpty;
}

/// Server-created Razorpay Order used to open Checkout.
class RazorpayCheckoutSession {
  const RazorpayCheckoutSession({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    this.requiresSignature = true,
  });

  /// Public Key Id only (`rzp_live_…` / `rzp_test_…`) — never the secret.
  final String keyId;

  /// Empty when using Standard Checkout without a server-created Order.
  final String orderId;
  final int amountPaise;
  final String currency;

  /// When true, success must include orderId + signature.
  final bool requiresSignature;

  bool get hasServerOrder => orderId.isNotEmpty;
}
