import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/callable_payload.dart';

/// Payload + result for an order-experience review submission.
class OrderExperienceReview {
  const OrderExperienceReview({
    required this.orderId,
    required this.userId,
    required this.rating,
    this.review = '',
    this.screenshotUrls = const [],
  });

  final String orderId;
  final String userId;
  final int rating;
  final String review;

  /// Reserved for a future screenshot attachment flow.
  final List<String> screenshotUrls;
}

class FeedbackSubmitResult {
  const FeedbackSubmitResult({
    required this.success,
    this.reviewId,
    this.message,
    this.alreadyExists = false,
  });

  final bool success;
  final String? reviewId;
  final String? message;
  final bool alreadyExists;
}

/// Submits low/high ratings to the backend `submitOrderExperienceReview`
/// callable (writes `order_reviews` + marks the order rated).
class FeedbackService {
  FeedbackService({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: 'us-central1',
            );

  final FirebaseFunctions _fn;

  Future<FeedbackSubmitResult> submit(OrderExperienceReview input) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = _platformLabel();
      final payload = sanitizeCallableData({
        'orderId': input.orderId,
        'userId': input.userId,
        'rating': input.rating,
        'review': input.review.trim(),
        'platform': platform,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'screenshotUrls': input.screenshotUrls,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });
      debugCallableData('submitOrderExperienceReview', payload);

      final res =
          await _fn.httpsCallable('submitOrderExperienceReview').call(payload);
      final data = Map<String, dynamic>.from(res.data as Map? ?? {});
      return FeedbackSubmitResult(
        success: data['success'] == true,
        reviewId: data['reviewId']?.toString(),
        message: data['message']?.toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        return FeedbackSubmitResult(
          success: true,
          alreadyExists: true,
          message: e.message,
        );
      }
      if (kDebugMode) {
        debugPrint(
          '[OrderReview] feedback submit failed: ${e.code} ${e.message}',
        );
      }
      return FeedbackSubmitResult(
        success: false,
        message: e.message ?? 'Could not submit feedback',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderReview] feedback submit error: $e');
      return FeedbackSubmitResult(
        success: false,
        message: 'Could not submit feedback. Check your connection.',
      );
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return defaultTargetPlatform.name;
  }
}
