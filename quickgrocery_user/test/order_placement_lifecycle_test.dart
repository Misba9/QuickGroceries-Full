import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/checkout_controller.dart';

class _QuietCart extends CartNotifier {
  @override
  CartState build() => CartState.empty;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failure and session end clear loading without rotating the idempotency key',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [cartProvider.overrideWith(_QuietCart.new)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(checkoutControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final notifier = container.read(checkoutControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final key = container.read(checkoutControllerProvider).idempotencyKey;

      expect(notifier.tryBeginPlacement(), isTrue);
      expect(container.read(checkoutControllerProvider).isPlacingOrder, isTrue);
      expect(notifier.tryBeginPlacement(), isFalse);
      expect(notifier.placementLocked, isTrue);

      notifier.finishPlacementFailure();
      final afterFailure = container.read(checkoutControllerProvider);
      expect(afterFailure.isPlacingOrder, isFalse);
      expect(afterFailure.idempotencyKey, key);
      expect(notifier.placementLocked, isFalse);

      expect(notifier.tryBeginPlacement(), isTrue);
      notifier.beginAwaitingExternalPayment(
        attemptId: notifier.currentAttemptId,
      );
      expect(
        container.read(checkoutControllerProvider).isPlacingOrder,
        isFalse,
      );
      expect(notifier.isAwaitingExternalPayment, isTrue);
      expect(notifier.placementLocked, isTrue);

      notifier.finishPlacementFailure();
      expect(notifier.isAwaitingExternalPayment, isFalse);
      expect(container.read(checkoutControllerProvider).idempotencyKey, key);

      expect(notifier.tryBeginPlacement(), isTrue);
      notifier.finishPlacementSuccess();
      expect(container.read(checkoutControllerProvider).isPlacingOrder, isTrue);
      expect(container.read(checkoutControllerProvider).idempotencyKey, key);
      notifier.endPlacementSession();
      expect(
        container.read(checkoutControllerProvider).isPlacingOrder,
        isFalse,
      );
      expect(notifier.placementLocked, isFalse);
    },
  );

  test(
    'cancel rotates the idempotency key and ignores a stale attempt callback',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [cartProvider.overrideWith(_QuietCart.new)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(checkoutControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final notifier = container.read(checkoutControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.tryBeginPlacement(), isTrue);
      final first = notifier.currentAttemptId;
      final key = container.read(checkoutControllerProvider).idempotencyKey;
      notifier.beginAwaitingExternalPayment(attemptId: first);
      expect(
        notifier.resumePlacementAfterPayment(
          attemptId: first,
          paymentId: 'pay_1',
          gatewayOrderId: 'order_1',
        ),
        isTrue,
      );

      notifier.cancelPlacement(attemptId: first);
      final afterCancel = container.read(checkoutControllerProvider);
      expect(afterCancel.isPlacingOrder, isFalse);
      expect(afterCancel.idempotencyKey, isNot(key));
      expect(notifier.placementLocked, isFalse);
      expect(notifier.pendingPaymentId, isNull);
      expect(notifier.pendingGatewayOrderId, isNull);
      expect(notifier.isAttemptCancelled(first), isTrue);
      expect(
        notifier.resumePlacementAfterPayment(
          attemptId: first,
          paymentId: 'pay_late',
        ),
        isFalse,
      );
      expect(
        container.read(checkoutControllerProvider).isPlacingOrder,
        isFalse,
      );

      expect(notifier.tryBeginPlacement(), isTrue);
      final second = notifier.currentAttemptId;
      final secondKey = container
          .read(checkoutControllerProvider)
          .idempotencyKey;
      expect(second, isNot(first));
      expect(secondKey, afterCancel.idempotencyKey);
      expect(container.read(checkoutControllerProvider).isPlacingOrder, isTrue);

      notifier.finishPlacementFailure(attemptId: first);
      notifier.cancelPlacement(attemptId: first);
      expect(
        notifier.resumePlacementAfterPayment(
          attemptId: first,
          paymentId: 'pay_stale',
        ),
        isFalse,
      );
      expect(container.read(checkoutControllerProvider).isPlacingOrder, isTrue);
      expect(notifier.placementLocked, isTrue);
      expect(
        container.read(checkoutControllerProvider).idempotencyKey,
        secondKey,
      );
      expect(notifier.pendingPaymentId, isNull);
    },
  );
}
