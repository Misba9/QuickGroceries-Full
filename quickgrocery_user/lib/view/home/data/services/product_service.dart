import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_product_debug.dart';

/// How the explore grid is ordered in Firestore.
///
/// Explore always uses [productIndex]. Documents missing `product_index` are
/// excluded by Firestore from `orderBy('product_index')` — see
/// [ProductIndexBackfill] and admin create paths that write the field.
enum HomeExploreSortKey {
  /// Admin reorder field — required for consistent explore pagination.
  productIndex,
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

  Future<QuerySnapshot<Map<String, dynamic>>> fetchFeatured({int limit = 12}) {
    return _ref
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchTrending({int limit = 12}) {
    return _ref
        .where('isTrending', isEqualTo: true)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchFlashSale({int limit = 16}) {
    return _ref
        .where('is_flash_sale', isEqualTo: true)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
  }

  // ── Flash sale (vendor-flagged) ─────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> watchFlashSale({int limit = 24}) {
    return _ref.where('is_flash_sale', isEqualTo: true).limit(limit).snapshots();
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

  /// First page ordered by `product_index` only (no documentId fallback).
  ///
  /// If the catalog has no indexed docs yet, attempts an in-place backfill
  /// of missing `product_index` values, then re-queries.
  Future<({QuerySnapshot<Map<String, dynamic>> snap, HomeExploreSortKey key})>
      fetchExploreFirstPage({
    int pageSize = 18,
  }) async {
    logHomeProducts(
      'explore first page: orderBy(product_index), limit=$pageSize',
    );

    var byIndex = await _ref.orderBy('product_index').limit(pageSize).get();
    logHomeProducts(
      'orderBy(product_index): raw docs=${byIndex.docs.length}',
    );

    if (byIndex.docs.isEmpty) {
      final repaired = await _ensureProductIndexesAndReload(pageSize: pageSize);
      if (repaired != null) {
        byIndex = repaired;
        logHomeProducts(
          'orderBy(product_index) after backfill: raw docs=${byIndex.docs.length}',
        );
      }
    }

    return (snap: byIndex, key: HomeExploreSortKey.productIndex);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchExploreNextPage({
    required DocumentSnapshot<Map<String, dynamic>> lastDoc,
    required HomeExploreSortKey sortKey,
    int pageSize = 18,
  }) {
    logHomeProducts(
      'explore next page: sort=productIndex after=${lastDoc.id} limit=$pageSize',
    );
    return _ref
        .orderBy('product_index')
        .startAfterDocument(lastDoc)
        .limit(pageSize)
        .get();
  }

  /// Assigns contiguous `product_index` on docs that lack the field, then
  /// reloads the first explore page. Returns null if writes are denied.
  Future<QuerySnapshot<Map<String, dynamic>>?> _ensureProductIndexesAndReload({
    required int pageSize,
  }) async {
    try {
      final unindexed =
          await _ref.orderBy(FieldPath.documentId).limit(pageSize * 3).get();
      if (unindexed.docs.isEmpty) return null;

      var next = 0;
      final batch = _firestore.batch();
      var ops = 0;
      for (final doc in unindexed.docs) {
        final data = doc.data();
        if (data['product_index'] is num) {
          final v = (data['product_index'] as num).toInt();
          if (v >= next) next = v + 1;
          continue;
        }
        batch.set(
          doc.reference,
          {'product_index': next++},
          SetOptions(merge: true),
        );
        ops++;
      }
      if (ops > 0) {
        await batch.commit();
        logHomeProducts('assigned product_index on $ops documents');
      }

      return _ref.orderBy('product_index').limit(pageSize).get();
    } catch (e) {
      logHomeProducts('product_index ensure failed: $e');
      return null;
    }
  }
}
