import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/review/review_config.dart';
import 'package:quickgrocery/core/review/review_preferences.dart';

void main() {
  late ReviewPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await ReviewPreferences.create();
  });

  group('ReviewPreferences', () {
    test('can prompt a fresh order', () {
      expect(
        prefs.canPromptOrder('order-1', laterReminder: const Duration(days: 3)),
        isTrue,
      );
    });

    test('No Thanks never prompts again', () async {
      await prefs.markDismissed('order-1');
      expect(
        prefs.canPromptOrder('order-1', laterReminder: const Duration(days: 3)),
        isFalse,
      );
      expect(prefs.isDismissed('order-1'), isTrue);
    });

    test('reviewed orders never prompt again', () async {
      await prefs.markReviewed('order-1');
      expect(
        prefs.canPromptOrder('order-1', laterReminder: const Duration(days: 3)),
        isFalse,
      );
    });

    test('Later snoozes until reminder window elapses', () async {
      await prefs.markLater('order-1');
      expect(
        prefs.canPromptOrder('order-1', laterReminder: const Duration(days: 3)),
        isFalse,
      );
      // Immediate reminder → still eligible.
      expect(
        prefs.canPromptOrder('order-1', laterReminder: Duration.zero),
        isTrue,
      );
    });

    test('store review cooldown', () async {
      const cooldown = Duration(days: 30);
      expect(prefs.canRequestStoreReview(cooldown: cooldown), isTrue);
      await prefs.markStoreReviewRequested();
      expect(prefs.canRequestStoreReview(cooldown: cooldown), isFalse);
      expect(
        prefs.canRequestStoreReview(cooldown: Duration.zero),
        isTrue,
      );
    });

    test('clearAll resets state', () async {
      await prefs.markReviewed('a');
      await prefs.markDismissed('b');
      await prefs.markLater('c');
      await prefs.markStoreReviewRequested();
      await prefs.clearAll();
      expect(prefs.reviewedOrders, isEmpty);
      expect(prefs.dismissedOrders, isEmpty);
      expect(prefs.laterReminders, isEmpty);
      expect(prefs.lastStoreReviewRequestDate, isNull);
    });
  });

  group('ReviewConfig', () {
    test('defaults match product requirements', () {
      const c = ReviewConfig.defaults;
      expect(c.promptDelay.inSeconds, inInclusiveRange(3, 5));
      expect(c.laterReminder, const Duration(days: 3));
      expect(c.storeReviewCooldown, const Duration(days: 30));
      expect(c.highRatingThreshold, 4);
      expect(c.enabled, isTrue);
    });
  });
}
