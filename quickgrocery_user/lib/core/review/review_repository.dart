import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/review/feedback_service.dart';
import 'package:quickgrocery/core/review/review_config.dart';
import 'package:quickgrocery/core/review/review_preferences.dart';
import 'package:quickgrocery/core/review/store_review_service.dart';

/// Coordinates prefs + backend feedback + native store review.
class ReviewRepository {
  ReviewRepository({
    required ReviewPreferences preferences,
    required FeedbackService feedbackService,
    required StoreReviewService storeReviewService,
    ReviewConfig config = ReviewConfig.defaults,
  })  : _prefs = preferences,
        _feedback = feedbackService,
        _store = storeReviewService,
        _config = config;

  final ReviewPreferences _prefs;
  final FeedbackService _feedback;
  final StoreReviewService _store;
  final ReviewConfig _config;

  ReviewConfig get config => _config;
  ReviewPreferences get preferences => _prefs;

  bool canPrompt(String orderId) =>
      _prefs.canPromptOrder(orderId, laterReminder: _config.laterReminder);

  Future<void> onLater(String orderId) => _prefs.markLater(orderId);

  Future<void> onNoThanks(String orderId) => _prefs.markDismissed(orderId);

  /// Persists the rating locally + remotely, then optionally triggers store review.
  Future<FeedbackSubmitResult> submitExperience({
    required String orderId,
    required String userId,
    required int rating,
    String review = '',
    List<String> screenshotUrls = const [],
  }) async {
    final result = await _feedback.submit(
      OrderExperienceReview(
        orderId: orderId,
        userId: userId,
        rating: rating,
        review: review,
        screenshotUrls: screenshotUrls,
      ),
    );

    // Always mark locally so we never re-prompt, even if the network failed —
    // the user already completed the flow. Remote can be retried later if needed.
    await _prefs.markReviewed(orderId);

    if (kDebugMode) {
      debugPrint(
        '[OrderReview] submitted order=$orderId rating=$rating '
        'ok=${result.success} already=${result.alreadyExists}',
      );
    }
    return result;
  }

  /// High ratings → native review (throttled). Returns whether native API ran.
  Future<StoreReviewOutcome> maybeRequestStoreReview() async {
    if (!_prefs.canRequestStoreReview(cooldown: _config.storeReviewCooldown)) {
      return StoreReviewOutcome.throttled;
    }

    await _prefs.markStoreReviewRequested();
    final requested = await _store.requestReview();
    if (requested) return StoreReviewOutcome.requested;

    final opened = await _store.openStoreListing();
    return opened
        ? StoreReviewOutcome.openedListing
        : StoreReviewOutcome.unavailable;
  }

  Future<bool> openStoreListing() => _store.openStoreListing();
}

enum StoreReviewOutcome {
  requested,
  openedListing,
  throttled,
  unavailable,
}
