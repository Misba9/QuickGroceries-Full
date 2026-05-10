import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_product_debug.dart';

/// How the explore grid is ordered in Firestore.
///
/// **Why two modes:** `orderBy('product_index')` **drops every document that
/// does not define `product_index`** (Firestore rule). Legacy catalogs often
/// omit this field, which produced an empty explore grid while categories
/// still loaded from `categories/`.
enum HomeExploreSortKey {
  /// Admin reorder field — preferred when present on documents.
  productIndex,

  /// Stable fallback — includes all documents, works without composite indexes.
  documentId,
}

/// Thin Firestore service for the `products` collection.
///
/// Implements the realtime queries the dynamic homepage needs:
/// trending, featured, by-special-cat (legacy), and a paginated explore feed.
class HomeProductService {
  HomeProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'products';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  // ── Trending ────────────────────────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> watchTrending({int limit = 12}) {
    return _ref
        .where('isTrending', isEqualTo: true)
        .limit(limit)
        .snapshots();
  }

  // ── Featured ────────────────────────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> watchFeatured({int limit = 12}) {
    return _ref
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots();
  }

  // ── Legacy `special_cat` rails ─────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> watchBySpecialCat(
    String specialCat, {
    int limit = 20,
  }) {
    return _ref
        .where('special_cat', isEqualTo: specialCat)
        .limit(limit)
        .snapshots();
  }

  // ── Explore (paginated) ────────────────────────────────────────────────

  /// First page: prefer `product_index` ordering when it returns data.
  /// If the snapshot is **empty** (common when no doc defines the field) or
  /// the query fails (missing index / permission), fall back to document ID
  /// ordering so legacy catalogs still render.
  Future<({QuerySnapshot<Map<String, dynamic>> snap, HomeExploreSortKey key})>
      fetchExploreFirstPage({
    int pageSize = 18,
  }) async {
    logHomeProducts('explore first page: attempting orderBy(product_index), '
        'limit=$pageSize');

    try {
      final byIndex =
          await _ref.orderBy('product_index').limit(pageSize).get();
      logHomeProducts(
        'orderBy(product_index): raw docs=${byIndex.docs.length}',
      );
      if (byIndex.docs.isNotEmpty) {
        return (snap: byIndex, key: HomeExploreSortKey.productIndex);
      }
      logHomeProducts(
        'orderBy(product_index): 0 documents — likely missing product_index '
        'on all products; falling back to documentId',
      );
    } on FirebaseException catch (e, st) {
      logHomeProducts(
        'orderBy(product_index) failed: code=${e.code} message=${e.message}',
      );
      logHomeProducts('$st');
    }

    final byId =
        await _ref.orderBy(FieldPath.documentId).limit(pageSize).get();
    logHomeProducts(
      'orderBy(documentId): raw docs=${byId.docs.length}',
    );
    return (snap: byId, key: HomeExploreSortKey.documentId);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchExploreNextPage({
    required DocumentSnapshot<Map<String, dynamic>> lastDoc,
    required HomeExploreSortKey sortKey,
    int pageSize = 18,
  }) {
    logHomeProducts(
      'explore next page: sort=$sortKey after=${lastDoc.id} limit=$pageSize',
    );
    final Query<Map<String, dynamic>> ordered = switch (sortKey) {
      HomeExploreSortKey.productIndex => _ref.orderBy('product_index'),
      HomeExploreSortKey.documentId => _ref.orderBy(FieldPath.documentId),
    };
    return ordered.startAfterDocument(lastDoc).limit(pageSize).get();
  }
}
