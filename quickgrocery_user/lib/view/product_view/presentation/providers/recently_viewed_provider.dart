import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/product_detail_providers.dart';

/// Notifier owning the persistent list of recently-viewed product ids.
///
/// - Reads/writes to [SharedPreferences] via [RecentlyViewedService].
/// - Exposed as the source of truth for both the recently-viewed rail
///   and the per-screen tracking call.
class RecentlyViewedIdsNotifier
    extends AutoDisposeAsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final svc = ref.read(recentlyViewedServiceProvider);
    return svc.read();
  }

  Future<void> track(String productId) async {
    final svc = ref.read(recentlyViewedServiceProvider);
    final updated = await svc.add(productId);
    state = AsyncData(updated);
  }

  Future<void> clear() async {
    final svc = ref.read(recentlyViewedServiceProvider);
    await svc.clear();
    state = const AsyncData([]);
  }
}

final recentlyViewedIdsProvider = AsyncNotifierProvider.autoDispose<
  RecentlyViewedIdsNotifier,
  List<String>
>(RecentlyViewedIdsNotifier.new);

/// Hydrated list — fetches the actual products for the persisted ids.
/// `excludeId` lets the detail screen hide the currently-viewed product
/// from its own "recently viewed" rail.
final recentlyViewedProductsProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, String>((ref, excludeId) async {
      final ids = await ref.watch(recentlyViewedIdsProvider.future);
      final filtered = ids.where((id) => id != excludeId).toList();
      if (filtered.isEmpty) return const [];
      return ref
          .watch(productDetailRepositoryProvider)
          .fetchRecentlyViewed(filtered);
    });
