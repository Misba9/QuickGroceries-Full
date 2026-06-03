import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CartFeedbackKind { success, error }

class CartFeedbackMessage {
  const CartFeedbackMessage({
    required this.text,
    this.kind = CartFeedbackKind.success,
  });

  final String text;
  final CartFeedbackKind kind;
}

/// Short-lived user message from cart actions (max limit, OOS, added, etc.).
final cartFeedbackProvider = StateProvider<CartFeedbackMessage?>((ref) => null);

void showCartErrorFeedback(WidgetRef ref, String message) {
  ref.read(cartFeedbackProvider.notifier).state = CartFeedbackMessage(
    text: message,
    kind: CartFeedbackKind.error,
  );
}

void showCartSuccessFeedback(WidgetRef ref, String message) {
  ref.read(cartFeedbackProvider.notifier).state = CartFeedbackMessage(
    text: message,
    kind: CartFeedbackKind.success,
  );
}
