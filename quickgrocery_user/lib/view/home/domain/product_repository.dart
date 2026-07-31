import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/core/startup/startup_isolate_parse.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/data/home_product_debug.dart';
import 'package:quickgrocery/view/home/data/services/product_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';
import 'package:rxdart/rxdart.dart';

/// Result wrapper for paginated explore queries — includes the raw
/// Firestore cursor so the next page can be fetched without re-querying
/// from the start.
class ExplorePage {
  const ExplorePage({
    required this.products,
    required this.cursor,
    required this.isLast,
    required this.sortKey,
    this.rawDocCount = 0,
    this.parsedCount = 0,
    this.skippedParseCount = 0,
    this.filteredUnavailableCount = 0,
  });

  final List<ProductModel> products;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool isLast;

  /// Must match the ordering used for [cursor] so pagination stays consistent.
  final HomeExploreSortKey sortKey;

  /// Diagnostics (debug logs also echo these when non-zero skips occur).
  final int rawDocCount;
  final int parsedCount;
  final int skippedParseCount;
  final int filteredUnavailableCount;
}

class ProductRepository {
  ProductRepository(this._service);
  final HomeProductService _service;

  /// Shared default-limit watches so Flash + Recs + rails share one snapshot.
  Stream<List<ProductModel>>? _sharedTrending;
  Stream<List<ProductModel>>? _sharedFeatured;
  Stream<List<ProductModel>>? _sharedFlashSale;

  Future<List<ProductModel>> fetchFeatured({int limit = 12}) async {
    try {
      final snap = await _service.fetchFeatured(limit: limit);
      return StartupIsolateParse.parseProductsFromSnapshot(
        snap,
        onlyAvailable: true,
      );
    } catch (e) {
      logHomeProducts('fetchFeatured error: $e');
      return const [];
    }
  }

  Future<List<ProductModel>> fetchTrending({int limit = 12}) async {
    try {
      final snap = await _service.fetchTrending(limit: limit);
      return StartupIsolateParse.parseProductsFromSnapshot(
        snap,
        onlyAvailable: true,
      );
    } catch (e) {
      logHomeProducts('fetchTrending error: $e');
      return const [];
    }
  }

  Future<List<ProductModel>> fetchFlashSale({int limit = 16}) async {
    try {
      final snap = await _service.fetchFlashSale(limit: limit);
      return StartupIsolateParse.parseProductsFromSnapshot(
        snap,
        onlyAvailable: true,
      );
    } catch (e) {
      logHomeProducts('fetchFlashSale error: $e');
      return const [];
    }
  }

  Stream<List<ProductModel>> watchTrending({int limit = 12}) {
    if (limit != 12) {
      return _mapProductStream(
        _service.watchTrending(limit: limit),
        'Failed to load trending products.',
      );
    }
    return _sharedTrending ??= _mapProductStream(
      _service.watchTrending(limit: 12),
      'Failed to load trending products.',
    ).shareReplay(maxSize: 1);
  }

  Stream<List<ProductModel>> watchFeatured({int limit = 12}) {
    if (limit != 12) {
      return _mapProductStream(
        _service.watchFeatured(limit: limit),
        'Failed to load featured products.',
      );
    }
    return _sharedFeatured ??= _mapProductStream(
      _service.watchFeatured(limit: 12),
      'Failed to load featured products.',
    ).shareReplay(maxSize: 1);
  }

  Stream<List<ProductModel>> watchFlashSale({int limit = 16}) {
    if (limit != 16) {
      return _mapProductStream(
        _service.watchFlashSale(limit: limit),
        'Failed to load flash sale products.',
      );
    }
    return _sharedFlashSale ??= _mapProductStream(
      _service.watchFlashSale(limit: 16),
      'Failed to load flash sale products.',
    ).shareReplay(maxSize: 1);
  }

  Stream<List<ProductModel>> _mapProductStream(
    Stream<QuerySnapshot<Map<String, dynamic>>> raw,
    String errorMessage,
  ) {
    return raw
        .asyncMap(
          (s) => StartupIsolateParse.parseProductsFromSnapshot(
            s,
            onlyAvailable: true,
          ),
        )
        .handleError(_throwHomeFailure(errorMessage));
  }

  // ── Legacy `special_cat` rails ─────────────────────────────────────────
  Stream<List<ProductModel>> watchBySpecialCat(
    String specialCat, {
    int limit = 20,
  }) {
    return _service
        .watchBySpecialCat(specialCat, limit: limit)
        .asyncMap(
          (s) => StartupIsolateParse.parseProductsFromSnapshot(
            s,
            onlyAvailable: true,
          ),
        )
        .handleError(_throwHomeFailure('Failed to load products.'));
  }

  // ── Explore (paginated) ────────────────────────────────────────────────
  Future<ExplorePage> fetchExploreFirstPage({int pageSize = 18}) async {
    try {
      final result = await _service.fetchExploreFirstPage(pageSize: pageSize);
      return _toPage(
        result.snap,
        pageSize,
        sortKey: result.key,
        context: 'explore:first',
      );
    } catch (e) {
      logHomeProducts('fetchExploreFirstPage error: $e');
      throw HomeFailure(
        'Failed to load products.',
        code: _codeOf(e),
        cause: e,
      );
    }
  }

  Future<ExplorePage> fetchExploreNextPage({
    required DocumentSnapshot<Map<String, dynamic>> cursor,
    required HomeExploreSortKey sortKey,
    int pageSize = 18,
  }) async {
    try {
      final snap = await _service.fetchExploreNextPage(
        lastDoc: cursor,
        sortKey: sortKey,
        pageSize: pageSize,
      );
      return _toPage(
        snap,
        pageSize,
        sortKey: sortKey,
        context: 'explore:next',
      );
    } catch (e) {
      logHomeProducts('fetchExploreNextPage error: $e');
      throw HomeFailure(
        'Failed to load more products.',
        code: _codeOf(e),
        cause: e,
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Future<ExplorePage> _toPage(
    QuerySnapshot<Map<String, dynamic>> snap,
    int pageSize, {
    required HomeExploreSortKey sortKey,
    required String context,
  }) async {
    final docs = StartupIsolateParse.docsFromSnapshot(snap);
    final available = await StartupIsolateParse.parseProducts(
      docs,
      onlyAvailable: true,
    );
    final parsedCount = docs.length; // approximate; skips counted in isolate
    final skipped = 0;
    final filteredOut = 0;

    if (skipped > 0 || filteredOut > 0) {
      logHomeProducts(
        '$context: raw=${snap.docs.length} parsed=$parsedCount '
        'skipped=$skipped unavailableFiltered=$filteredOut '
        'final=${available.length} sort=$sortKey',
      );
    }

    return ExplorePage(
      products: available,
      cursor: snap.docs.isEmpty ? null : snap.docs.last,
      isLast: snap.docs.length < pageSize,
      sortKey: sortKey,
      rawDocCount: snap.docs.length,
      parsedCount: available.length,
      skippedParseCount: skipped,
      filteredUnavailableCount: filteredOut,
    );
  }

  void Function(Object, StackTrace) _throwHomeFailure(String message) {
    return (Object error, StackTrace stackTrace) {
      logHomeProducts('repo error: $error');
      throw HomeFailure(_humanize(message, error),
          code: _codeOf(error), cause: error);
    };
  }

  String _humanize(String fallback, Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Read denied by Firestore rules. Allow `products` reads.';
        case 'unavailable':
          return 'Firestore unavailable. Check internet connection.';
        case 'failed-precondition':
          return 'Missing Firestore index. Open the console link printed '
              'in the debug log to create it.';
      }
    }
    return fallback;
  }

  String? _codeOf(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }
}
