import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quickgrocery/core/firebase/callable_payload.dart';
import 'package:quickgrocery/models/rating_model.dart';

class ReviewApiClient {
  ReviewApiClient({FirebaseFunctions? functions})
    : _fn =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(),
            region: 'us-central1',
          );

  final FirebaseFunctions _fn;

  Future<Map<String, dynamic>> canReview({
    required String productId,
    required String productName,
  }) async {
    final payload = sanitizeCallableData({
      'productId': productId,
      'productName': productName,
    });
    debugCallableData('canReviewProduct', payload);
    final res = await _fn.httpsCallable('canReviewProduct').call(payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<String> submit({
    required String productId,
    required String productName,
    required String vendorId,
    required String orderId,
    required String userName,
    required String reviewText,
    required List<String> reviewImages,
    required String reviewVideo,
    required CategoryRatings categoryRatings,
  }) async {
    final payload = sanitizeCallableData({
      'productId': productId,
      'productName': productName,
      'vendorId': vendorId,
      'orderId': orderId,
      'userName': userName,
      'reviewText': reviewText,
      'reviewImages': reviewImages,
      'reviewVideo': reviewVideo,
      'categoryRatings': categoryRatings.toMap(),
    });
    debugCallableData('submitProductReview', payload);
    final res = await _fn.httpsCallable('submitProductReview').call(payload);
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['reviewId']?.toString() ?? '';
  }

  Future<void> markHelpful(String reviewId) async {
    final payload = sanitizeCallableData({'reviewId': reviewId});
    debugCallableData('markReviewHelpful', payload);
    await _fn.httpsCallable('markReviewHelpful').call(payload);
  }

  Future<void> report(String reviewId) async {
    final payload = sanitizeCallableData({'reviewId': reviewId});
    debugCallableData('reportProductReview', payload);
    await _fn.httpsCallable('reportProductReview').call(payload);
  }

  Future<void> update({
    required String reviewId,
    required String reviewText,
    required List<String> reviewImages,
    required String reviewVideo,
    required CategoryRatings categoryRatings,
  }) async {
    final payload = sanitizeCallableData({
      'reviewId': reviewId,
      'reviewText': reviewText,
      'reviewImages': reviewImages,
      'reviewVideo': reviewVideo,
      'categoryRatings': categoryRatings.toMap(),
    });
    debugCallableData('updateProductReview', payload);
    await _fn.httpsCallable('updateProductReview').call(payload);
  }

  Future<void> deleteReview(String reviewId) async {
    final payload = sanitizeCallableData({'reviewId': reviewId});
    debugCallableData('deleteProductReview', payload);
    await _fn.httpsCallable('deleteProductReview').call(payload);
  }
}
