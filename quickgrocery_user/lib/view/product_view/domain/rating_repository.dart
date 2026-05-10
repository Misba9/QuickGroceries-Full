import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/models/rating_model.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';
import 'package:quickgrocery/view/product_view/data/services/rating_service.dart';

/// Aggregated ratings summary derived from the raw rating documents.
class RatingSummary {
  const RatingSummary({
    required this.average,
    required this.total,
    required this.distribution,
  });

  final double average;
  final int total;

  /// Star -> count, e.g. {5: 80, 4: 30, 3: 6, 2: 2, 1: 0}.
  final Map<int, int> distribution;

  static const empty = RatingSummary(
    average: 0,
    total: 0,
    distribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  );

  /// Percentage of [total] for a given [star] bucket. Returns 0 when empty.
  double ratioFor(int star) {
    if (total == 0) return 0;
    final count = distribution[star] ?? 0;
    return count / total;
  }
}

class RatingRepository {
  RatingRepository(this._service);
  final ProductRatingService _service;

  /// Realtime stream of all ratings for a product, sorted newest-first.
  Stream<List<RatingModel>> watchRatings(String productId, {int limit = 50}) {
    return _service
        .watchRatings(productId, limit: limit)
        .map((snap) {
          final items = snap.docs
              .map((d) => RatingModel.fromFirestore(d.data(), d.id))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        })
        .handleError(_throwFailure('Failed to load reviews.'));
  }

  /// Convenience derivation; consumers can call this on the same data
  /// stream to avoid double Firestore subscriptions.
  RatingSummary summarize(List<RatingModel> ratings) {
    if (ratings.isEmpty) return RatingSummary.empty;
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double sum = 0;
    for (final r in ratings) {
      sum += r.rating;
      final bucket = r.rating.round().clamp(1, 5);
      dist[bucket] = (dist[bucket] ?? 0) + 1;
    }
    return RatingSummary(
      average: sum / ratings.length,
      total: ratings.length,
      distribution: dist,
    );
  }

  void Function(Object, StackTrace) _throwFailure(String message) {
    return (Object error, StackTrace _) {
      if (error is HomeFailure) throw error;
      throw HomeFailure(message, code: _codeOf(error), cause: error);
    };
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
