import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Short-lived user message from cart actions (max limit, OOS, etc.).
final cartFeedbackProvider = StateProvider<String?>((ref) => null);

void showCartFeedback(WidgetRef ref, String message) {
  ref.read(cartFeedbackProvider.notifier).state = message;
}
