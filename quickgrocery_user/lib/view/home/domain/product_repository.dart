import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/data/home_product_debug.dart';
import 'package:quickgrocery/view/home/data/services/product_service.dart';
import 'package:quickgrocery/view/home/domain/home_failure.dart';

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

  // ── Trending / Featured ─────────────────────────────────────────────────
  Stream<List<ProductModel>> watchTrending({int limit = 12}) {
    return _service
        .watchTrending(limit: limit)
        .map((s) => _mapSnapshot(s, onlyAvailable: true, label: 'trending'))
        .handleError(_throwHomeFailure('Failed to load trending products.'));
  }

  Stream<List<ProductModel>> watchFeatured({int limit = 12}) {
    return _service
        .watchFeatured(limit: limit)
        .map((s) => _mapSnapshot(s, onlyAvailable: true, label: 'featured'))
        .handleError(_throwHomeFailure('Failed to load featured products.'));
  }

  Future<List<ProductModel>> fetchFeatured({int limit = 12}) async {
    try {
      final snap = await _service.fetchFeatured(limit: limit);
      return _mapSnapshot(snap, onlyAvailable: true, label: 'featured');
    } catch (e) {
      logHomeProducts('fetchFeatured error: $e');
      return const [];
    }
  }

  Stream<List<ProductModel>> watchFlashSale({int limit = 16}) {
    return _service
        .watchFlashSale(limit: limit)
        .map((s) => _mapSnapshot(s, onlyAvailable: true, label: 'flash_sale'))
        .handleError(_throwHomeFailure('Failed to load flash sale products.'));
  }

  // ── Legacy `special_cat` rails ─────────────────────────────────────────
  Stream<List<ProductModel>> watchBySpecialCat(
    String specialCat, {
    int limit = 20,
  }) {
    return _service
        .watchBySpecialCat(specialCat, limit: limit)
        .map((s) =>
            _mapSnapshot(s, onlyAvailable: true, label: 'special_cat:$specialCat'))
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
  ExplorePage _toPage(
    QuerySnapshot<Map<String, dynamic>> snap,
    int pageSize, {
    required HomeExploreSortKey sortKey,
    required String context,
  }) {
    final parsed = <ProductModel>[];
    var skipped = 0;
    for (final d in snap.docs) {
      final r = _tryParseProduct(d.data(), d.id, context);
      if (r == null) {
        skipped++;
        continue;
      }
      parsed.add(r);
    }

    final available = parsed.where((p) => p.isAvailable).toList();
    final filteredOut = parsed.length - available.length;

    if (skipped > 0 || filteredOut > 0) {
      logHomeProducts(
        '$context: raw=${snap.docs.length} parsed=${parsed.length} '
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
      parsedCount: parsed.length,
      skippedParseCount: skipped,
      filteredUnavailableCount: filteredOut,
    );
  }

  ProductModel? _tryParseProduct(
    Map<String, dynamic> data,
    String id,
    String context,
  ) {
    try {
      return ProductModel.fromFirestore(data, id);
    } catch (e, st) {
      logHomeProducts(
        '$context: parse FAILED id=$id error=$e',
      );
      logHomeProducts('$st');
      return null;
    }
  }

  List<ProductModel> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap, {
    bool onlyAvailable = false,
    required String label,
  }) {
    final out = <ProductModel>[];
    var skipped = 0;
    for (final d in snap.docs) {
      final r = _tryParseProduct(d.data(), d.id, label);
      if (r == null) {
        skipped++;
        continue;
      }
      if (!onlyAvailable || r.isAvailable) {
        out.add(r);
      }
    }
    if (skipped > 0) {
      logHomeProducts(
        '$label stream: docs=${snap.docs.length} kept=${out.length} '
        'skipped=$skipped',
      );
    }
    return out;
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
