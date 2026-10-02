import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/review/feedback_service.dart';
import 'package:quickgrocery/core/review/review_config.dart';
import 'package:quickgrocery/core/review/review_dialog.dart';
import 'package:quickgrocery/core/review/review_preferences.dart';
import 'package:quickgrocery/core/review/review_repository.dart';
import 'package:quickgrocery/core/review/store_review_service.dart';

/// Orchestrates when and how to show the post-delivery review flow.
///
/// Safe to call from:
/// - Delivered order tracking screen (with delay)
/// - App resume / landing bootstrap
///
/// Does **not** interrupt OTP, payment, checkout, or live (non-delivered)
/// tracking routes — queues until the user reaches a safe screen.
class OrderReviewService {
  OrderReviewService._({
    required ReviewRepository repository,
  }) : _repo = repository;

  static OrderReviewService? _instance;

  /// Lazily creates the singleton with production dependencies.
  static Future<OrderReviewService> instance({
    ReviewConfig config = ReviewConfig.defaults,
  }) async {
    if (_instance != null) return _instance!;
    final prefs = await ReviewPreferences.create();
    final repo = ReviewRepository(
      preferences: prefs,
      feedbackService: FeedbackService(),
      storeReviewService: StoreReviewService(config: config),
      config: config,
    );
    _instance = OrderReviewService._(repository: repo);
    return _instance!;
  }

  /// Test / DI hook.
  @visibleForTesting
  static void bindForTest(OrderReviewService service) {
    _instance = service;
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }

  /// Testing constructor.
  @visibleForTesting
  factory OrderReviewService.forTest(ReviewRepository repository) {
    return OrderReviewService._(repository: repository);
  }

  final ReviewRepository _repo;

  bool _dialogVisible = false;
  String? _pendingOrderId;
  String? _pendingUserId;

  ReviewRepository get repository => _repo;

  /// Routes where we must wait before showing any review UI.
  static const unsafeRoutes = {
    AppRoutes.otp,
    AppRoutes.login,
    AppRoutes.payment,
    AppRoutes.checkout,
    // Live tracking while in transit uses the same route name;
    // callers on delivered screens pass [forceOnDeliveredScreen: true].
  };

  bool get isSafeToShow {
    final top = appRouteObserver.topRouteName;
    if (top == null) return true;
    return !unsafeRoutes.contains(top);
  }

  /// Primary entry: prompt for a specific delivered order.
  ///
  /// [delay] waits [ReviewConfig.promptDelay] (default ~4s) after the call.
  /// [forceOnDeliveredScreen] skips the tracking-route block when the caller
  /// already knows the order is delivered.
  Future<void> maybePromptForOrder({
    required BuildContext context,
    required String orderId,
    required String userId,
    bool delay = true,
    bool forceOnDeliveredScreen = false,
  }) async {
    if (!_repo.config.enabled) return;
    if (orderId.isEmpty || userId.isEmpty) return;
    if (!_repo.canPrompt(orderId)) {
      if (kDebugMode) {
        debugPrint('[OrderReview] skip — already handled order=$orderId');
      }
      return;
    }
    if (_dialogVisible) {
      _pendingOrderId = orderId;
      _pendingUserId = userId;
      return;
    }

    if (!forceOnDeliveredScreen && !isSafeToShow) {
      if (kDebugMode) {
        debugPrint(
          '[OrderReview] defer — unsafe route=${appRouteObserver.topRouteName}',
        );
      }
      _pendingOrderId = orderId;
      _pendingUserId = userId;
      return;
    }

    if (delay) {
      await Future<void>.delayed(_repo.config.promptDelay);
      if (!context.mounted) return;
      // Re-check after delay — user may have navigated away or already rated.
      if (!_repo.canPrompt(orderId)) return;
      if (!forceOnDeliveredScreen && !isSafeToShow) {
        _pendingOrderId = orderId;
        _pendingUserId = userId;
        return;
      }
    }

    await _runPromptFlow(
      context: context,
      orderId: orderId,
      userId: userId,
    );
  }

  /// App-open / resume entry: pick the newest eligible delivered order.
  Future<void> maybePromptForDeliveredOrders({
    required BuildContext context,
    required List<({String orderId, String userId})> candidates,
  }) async {
    if (!_repo.config.enabled || candidates.isEmpty) return;
    for (final c in candidates) {
      if (_repo.canPrompt(c.orderId)) {
        await maybePromptForOrder(
          context: context,
          orderId: c.orderId,
          userId: c.userId,
          delay: true,
        );
        return;
      }
    }
  }

  /// Flush a deferred prompt when navigation becomes safe.
  Future<void> flushPendingIfSafe(BuildContext context) async {
    final orderId = _pendingOrderId;
    final userId = _pendingUserId;
    if (orderId == null || userId == null) return;
    if (!isSafeToShow || _dialogVisible) return;
    _pendingOrderId = null;
    _pendingUserId = null;
    await maybePromptForOrder(
      context: context,
      orderId: orderId,
      userId: userId,
      delay: false,
    );
  }

  Future<void> _runPromptFlow({
    required BuildContext context,
    required String orderId,
    required String userId,
  }) async {
    if (_dialogVisible || !context.mounted) return;
    _dialogVisible = true;

    try {
      if (kDebugMode) {
        debugPrint('[OrderReview] showing prompt for order=$orderId');
      }

      final action = await showOrderReviewPromptDialog(context);
      if (!context.mounted) return;
      if (action == null) return;

      if (action == ReviewPromptAction.later) {
        await _repo.onLater(orderId);
        return;
      }
      if (action == ReviewPromptAction.noThanks) {
        await _repo.onNoThanks(orderId);
        return;
      }

      if (!context.mounted) return;
      final rating = await showStarRatingDialog(context);
      if (!context.mounted || rating == null || rating < 1) return;

      final threshold = _repo.config.highRatingThreshold;
      if (rating >= threshold) {
        // Happy path: persist quietly, then native store review.
        final result = await _repo.submitExperience(
          orderId: orderId,
          userId: userId,
          rating: rating,
        );
        if (!context.mounted) return;
        if (!result.success && !result.alreadyExists) {
          AppSnackBar.info(
            result.message ?? 'Saved locally. We’ll sync when online.',
            context: context,
          );
        }

        final outcome = await _repo.maybeRequestStoreReview();
        if (!context.mounted) return;
        if (outcome == StoreReviewOutcome.unavailable) {
          final open = await showOpenStoreReviewDialog(context);
          if (open && context.mounted) {
            await _repo.openStoreListing();
          }
        } else if (kDebugMode) {
          debugPrint('[OrderReview] store review outcome=$outcome');
        }
      } else {
        // Low rating → internal feedback (never store review).
        if (!context.mounted) return;
        final text = await showInternalFeedbackForm(
          context,
          rating: rating,
        );
        if (!context.mounted) return;
        final result = await _repo.submitExperience(
          orderId: orderId,
          userId: userId,
          rating: rating,
          review: text ?? '',
        );
        if (!context.mounted) return;
        if (result.success || result.alreadyExists) {
          AppSnackBar.success(
            'Thanks for your feedback',
            context: context,
          );
        } else {
          AppSnackBar.error(
            result.message ?? 'Could not submit feedback',
            context: context,
          );
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[OrderReview] flow error: $e\n$st');
      }
    } finally {
      _dialogVisible = false;
    }
  }

  /// Resolve the signed-in uid for submissions.
  static String? currentUserId() => FirebaseAuth.instance.currentUser?.uid;

  /// Convenience for widgets that only have a [BuildContext].
  static BuildContext? rootContext() => rootNavigatorKey.currentContext;
}
