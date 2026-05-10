import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';
import 'package:quickgrocery/view/product_view/data/services/product_detail_service.dart';

class ProductDetailRepository {
  ProductDetailRepository(this._service);
  final ProductDetailService _service;

  /// Realtime model stream for a single product. Throws [HomeFailure] when
  /// the document is missing or unreachable.
  Stream<ProductModel> watchProduct(String id) {
    return _service.watchProduct(id).map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        throw const HomeFailure('Product not found.', code: 'not-found');
      }
      return ProductModel.fromFirestore(data, doc.id);
    }).handleError(_throwFailure('Failed to load product.'));
  }

  Future<ProductModel> fetchProduct(String id) async {
    try {
      final doc = await _service.fetchProduct(id);
      final data = doc.data();
      if (!doc.exists || data == null) {
        throw const HomeFailure('Product not found.', code: 'not-found');
      }
      return ProductModel.fromFirestore(data, doc.id);
    } catch (e) {
      if (e is HomeFailure) rethrow;
      throw HomeFailure(
        'Failed to load product.',
        code: _codeOf(e),
        cause: e,
      );
    }
  }

  /// Realtime stream of products in the same category, with the current
  /// product filtered out client-side and the result clamped to [limit].
  Stream<List<ProductModel>> watchSimilarProducts({
    required String category,
    required String excludeId,
    int limit = 10,
  }) {
    if (category.isEmpty) return Stream.value(const []);
    return _service
        .watchSimilarProducts(
          category: category,
          excludeId: excludeId,
          limit: limit,
        )
        .map((snap) {
          final items = snap.docs
              .map((d) => ProductModel.fromFirestore(d.data(), d.id))
              .where((p) => p.id != excludeId)
              .where((p) => p.isAvailable)
              .toList();
          if (items.length > limit) items.removeRange(limit, items.length);
          return items;
        })
        .handleError(_throwFailure('Failed to load similar products.'));
  }

  Future<List<ProductModel>> fetchRecentlyViewed(List<String> ids) async {
    if (ids.isEmpty) return const [];
    try {
      final snap = await _service.fetchProductsByIds(ids);
      final byId = {
        for (final d in snap.docs)
          d.id: ProductModel.fromFirestore(d.data(), d.id),
      };
      // Preserve the order of [ids] (newest first).
      return ids
          .map((id) => byId[id])
          .whereType<ProductModel>()
          .where((p) => p.isAvailable)
          .toList();
    } catch (e) {
      throw HomeFailure(
        'Failed to load recently viewed products.',
        code: _codeOf(e),
        cause: e,
      );
    }
  }

  // ── Favorites ──────────────────────────────────────────────────────────
  bool isFavoritedBy(ProductModel product, String? uid) {
    if (uid == null) return false;
    // The legacy `is_favorite` field isn't part of [ProductModel], so we
    // rely on the live document. Callers should use [watchIsFavorite].
    return false;
  }

  Stream<bool> watchIsFavorite(String productId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _service.watchProduct(productId).map((doc) {
      final data = doc.data();
      if (data == null) return false;
      final list = data['is_favorite'];
      if (list is List) return list.contains(uid);
      return false;
    });
  }

  Future<void> toggleFavorite(String productId, bool nowFavorite) async {
    try {
      if (nowFavorite) {
        await _service.addToFavorites(productId);
      } else {
        await _service.removeFromFavorites(productId);
      }
    } catch (e) {
      throw HomeFailure(
        'Failed to update favorites.',
        code: _codeOf(e),
        cause: e,
      );
    }
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
