import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quickgrocery/models/rating_model.dart';

class ReviewApiClient {
  ReviewApiClient({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: 'us-central1',
            );

  final FirebaseFunctions _fn;

  Future<Map<String, dynamic>> canReview({
    required String productId,
    required String productName,
  }) async {
    final res = await _fn.httpsCallable('canReviewProduct').call({
      'productId': productId,
      'productName': productName,
    });
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
    final res = await _fn.httpsCallable('submitProductReview').call({
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
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['reviewId']?.toString() ?? '';
  }

  Future<void> markHelpful(String reviewId) async {
    await _fn.httpsCallable('markReviewHelpful').call({'reviewId': reviewId});
  }

  Future<void> report(String reviewId) async {
    await _fn.httpsCallable('reportProductReview').call({'reviewId': reviewId});
  }

  Future<void> update({
    required String reviewId,
    required String reviewText,
    required List<String> reviewImages,
    required String reviewVideo,
    required CategoryRatings categoryRatings,
  }) async {
    await _fn.httpsCallable('updateProductReview').call({
      'reviewId': reviewId,
      'reviewText': reviewText,
      'reviewImages': reviewImages,
      'reviewVideo': reviewVideo,
      'categoryRatings': categoryRatings.toMap(),
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await _fn.httpsCallable('deleteProductReview').call({'reviewId': reviewId});
  }
}
