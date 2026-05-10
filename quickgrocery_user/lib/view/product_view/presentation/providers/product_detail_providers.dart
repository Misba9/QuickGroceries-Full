import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/models/rating_model.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart'
    show firestoreProvider;
import 'package:quickgrocery/view/product_view/data/services/product_detail_service.dart';
import 'package:quickgrocery/view/product_view/data/services/rating_service.dart';
import 'package:quickgrocery/view/product_view/data/services/recently_viewed_service.dart';
import 'package:quickgrocery/view/product_view/domain/product_detail_repository.dart';
import 'package:quickgrocery/view/product_view/domain/rating_repository.dart';

// ── Service providers ──────────────────────────────────────────────────────
final productDetailServiceProvider = Provider<ProductDetailService>((ref) {
  return ProductDetailService(firestore: ref.watch(firestoreProvider));
});

final productRatingServiceProvider = Provider<ProductRatingService>((ref) {
  return ProductRatingService(firestore: ref.watch(firestoreProvider));
});

final recentlyViewedServiceProvider = Provider<RecentlyViewedService>((ref) {
  return RecentlyViewedService();
});

// ── Repository providers ───────────────────────────────────────────────────
final productDetailRepositoryProvider = Provider<ProductDetailRepository>((
  ref,
) {
  return ProductDetailRepository(ref.watch(productDetailServiceProvider));
});

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository(ref.watch(productRatingServiceProvider));
});

// ── Realtime data providers ────────────────────────────────────────────────

/// Live document stream for a product. Falls back to the bootstrap product
/// (passed via [productDetailBootstrapProvider]) before the first frame.
final productByIdStreamProvider = StreamProvider.autoDispose
    .family<ProductModel, String>((ref, id) {
      return ref.watch(productDetailRepositoryProvider).watchProduct(id);
    });

final ratingsStreamProvider = StreamProvider.autoDispose
    .family<List<RatingModel>, String>((ref, productId) {
      return ref.watch(ratingRepositoryProvider).watchRatings(productId);
    });

final ratingSummaryProvider = Provider.autoDispose.family<RatingSummary, String>(
  (ref, productId) {
    final ratings = ref.watch(ratingsStreamProvider(productId)).valueOrNull;
    if (ratings == null) return RatingSummary.empty;
    return ref.watch(ratingRepositoryProvider).summarize(ratings);
  },
);

/// Family params for similar-products query.
class SimilarProductsKey {
  const SimilarProductsKey({required this.category, required this.excludeId});
  final String category;
  final String excludeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimilarProductsKey &&
          other.category == category &&
          other.excludeId == excludeId;

  @override
  int get hashCode => Object.hash(category, excludeId);
}

final similarProductsStreamProvider = StreamProvider.autoDispose
    .family<List<ProductModel>, SimilarProductsKey>((ref, key) {
      return ref
          .watch(productDetailRepositoryProvider)
          .watchSimilarProducts(
            category: key.category,
            excludeId: key.excludeId,
            limit: 10,
          );
    });

/// Live favorite flag derived from the product document.
final isFavoriteStreamProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, productId) {
    return ref
        .watch(productDetailRepositoryProvider)
        .watchIsFavorite(productId);
  },
);
