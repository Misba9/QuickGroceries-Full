import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/data/home_product_debug.dart';
import 'package:quickgrocery/view/home/data/services/product_service.dart';
import 'package:quickgrocery/view/home/domain/product_repository.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';

/// Immutable state for the paginated explore feed.
class ExploreState {
  const ExploreState({
    this.products = const [],
    this.cursor,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.sortKey = HomeExploreSortKey.productIndex,
    this.diagnosticRawDocs = 0,
    this.diagnosticSkippedParse = 0,
    this.diagnosticFilteredUnavailable = 0,
  });

  final List<ProductModel> products;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool isLoadingMore;
  final bool hasReachedEnd;

  /// Firestore ordering key — **must** stay aligned with [cursor] for
  /// `startAfterDocument` to behave correctly.
  final HomeExploreSortKey sortKey;

  /// Last explore fetch diagnostics (debug / empty-state hints).
  final int diagnosticRawDocs;
  final int diagnosticSkippedParse;
  final int diagnosticFilteredUnavailable;

  ExploreState copyWith({
    List<ProductModel>? products,
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    HomeExploreSortKey? sortKey,
    int? diagnosticRawDocs,
    int? diagnosticSkippedParse,
    int? diagnosticFilteredUnavailable,
  }) {
    return ExploreState(
      products: products ?? this.products,
      cursor: cursor ?? this.cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      sortKey: sortKey ?? this.sortKey,
      diagnosticRawDocs: diagnosticRawDocs ?? this.diagnosticRawDocs,
      diagnosticSkippedParse:
          diagnosticSkippedParse ?? this.diagnosticSkippedParse,
      diagnosticFilteredUnavailable: diagnosticFilteredUnavailable ??
          this.diagnosticFilteredUnavailable,
    );
  }
}

/// AsyncNotifier driving the paginated explore feed.
///
/// - First load is exposed as the AsyncValue itself (loading / error / data).
/// - Subsequent pages are loaded via [loadNextPage] which appends to
///   the existing list without flipping the AsyncValue back to `loading`.
class ExploreProductsNotifier
    extends AutoDisposeAsyncNotifier<ExploreState> {
  static const int _pageSize = 18;

  late final ProductRepository _repo = ref.read(productRepositoryProvider);

  @override
  Future<ExploreState> build() async {
    final ExplorePage page = await _repo.fetchExploreFirstPage(
      pageSize: _pageSize,
    );
    return ExploreState(
      products: page.products,
      cursor: page.cursor,
      hasReachedEnd: page.isLast,
      sortKey: page.sortKey,
      diagnosticRawDocs: page.rawDocCount,
      diagnosticSkippedParse: page.skippedParseCount,
      diagnosticFilteredUnavailable: page.filteredUnavailableCount,
    );
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isLoadingMore || current.hasReachedEnd) return;
    if (current.cursor == null) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final next = await _repo.fetchExploreNextPage(
        cursor: current.cursor!,
        sortKey: current.sortKey,
        pageSize: _pageSize,
      );
      state = AsyncData(
        current.copyWith(
          products: [...current.products, ...next.products],
          cursor: next.cursor ?? current.cursor,
          hasReachedEnd: next.isLast,
          sortKey: next.sortKey,
          isLoadingMore: false,
          diagnosticRawDocs: current.diagnosticRawDocs + next.rawDocCount,
          diagnosticSkippedParse:
              current.diagnosticSkippedParse + next.skippedParseCount,
          diagnosticFilteredUnavailable: current.diagnosticFilteredUnavailable +
              next.filteredUnavailableCount,
        ),
      );
    } catch (e, st) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      logHomeProducts('explore loadNextPage failed: $e\n$st');
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final exploreProductsProvider =
    AsyncNotifierProvider.autoDispose<ExploreProductsNotifier, ExploreState>(
      ExploreProductsNotifier.new,
    );
