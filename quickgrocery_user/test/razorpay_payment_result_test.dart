import 'package:flutter_test/flutter_test.dart';
import 'package:quickgrocery/view/payment/domain/razorpay_payment_result.dart';

void main() {
  group('RazorpayPaymentResult', () {
    test('isComplete requires paymentId, orderId, and signature', () {
      expect(
        const RazorpayPaymentResult(
          paymentId: 'pay_1',
          orderId: 'order_1',
          signature: 'sig',
        ).isComplete,
        isTrue,
      );
      expect(
        const RazorpayPaymentResult(
          paymentId: '',
          orderId: 'order_1',
          signature: 'sig',
        ).isComplete,
        isFalse,
      );
      expect(
        const RazorpayPaymentResult(
          paymentId: 'pay_1',
          orderId: '',
          signature: 'sig',
        ).isComplete,
        isFalse,
      );
      expect(
        const RazorpayPaymentResult(
          paymentId: 'pay_1',
          orderId: 'order_1',
          signature: '',
        ).isComplete,
        isFalse,
      );
    });
  });

  group('RazorpayCheckoutSession', () {
    test('holds server-issued checkout fields', () {
      const session = RazorpayCheckoutSession(
        keyId: 'rzp_test_x',
        orderId: 'order_abc',
        amountPaise: 49900,
        currency: 'INR',
      );
      expect(session.keyId, startsWith('rzp_'));
      expect(session.amountPaise, 49900);
      expect(session.currency, 'INR');
      expect(session.hasServerOrder, isTrue);
      expect(session.requiresSignature, isTrue);
    });

    test('public-key fallback omits server order', () {
      const session = RazorpayCheckoutSession(
        keyId: 'rzp_live_x',
        orderId: '',
        amountPaise: 4200,
        currency: 'INR',
        requiresSignature: false,
      );
      expect(session.hasServerOrder, isFalse);
      expect(session.requiresSignature, isFalse);
    });
  });
}
