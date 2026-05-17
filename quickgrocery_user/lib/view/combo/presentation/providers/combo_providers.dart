import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/models/combo_offer_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/combo/data/combo_offer_service.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';

final comboOfferServiceProvider = Provider<ComboOfferService>((ref) {
  return ComboOfferService();
});

final activeComboOffersProvider = StreamProvider<List<ComboOfferModel>>((ref) {
  return ref.watch(comboOfferServiceProvider).watchActiveCombos();
});

final trendingComboOffersProvider = Provider<AsyncValue<List<ComboOfferModel>>>((ref) {
  final async = ref.watch(activeComboOffersProvider);
  return async.whenData((list) {
    final trending = list.where((c) => c.isTrending || c.isFlashSale).toList();
    return trending.isEmpty ? list.take(6).toList() : trending;
  });
});

final flashComboOffersProvider = Provider<AsyncValue<List<ComboOfferModel>>>((ref) {
  final async = ref.watch(activeComboOffersProvider);
  return async.whenData((list) => list.where((c) => c.isFlashSale).toList());
});

/// Resolves live [ProductModel] rows for a combo from cached home product streams.
final comboProductsResolverProvider =
    Provider.family<AsyncValue<List<ProductModel>>, ComboOfferModel>((ref, combo) {
  final trending = ref.watch(trendingProductsStreamProvider);
  final featured = ref.watch(featuredProductsStreamProvider);

  return trending.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (trend) {
      return featured.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (feat) {
          final all = <String, ProductModel>{};
          for (final p in [...trend, ...feat]) {
            all[p.id] = p;
          }
          final resolved = <ProductModel>[];
          for (final id in combo.productIds) {
            final p = all[id];
            if (p != null) resolved.add(p);
          }
          return AsyncData(resolved);
        },
      );
    },
  );
});
