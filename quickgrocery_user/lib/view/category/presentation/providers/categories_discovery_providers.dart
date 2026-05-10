import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/models/promo_model.dart';
import 'package:quickgrocery/view/category/data/services/promo_service.dart';
import 'package:quickgrocery/view/category/domain/promo_repository.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';

/// Riverpod wiring for the new Categories discovery screen.
///
/// Reuses the existing `firestoreProvider`, banner / category / product
/// streams from `home_providers.dart` and adds a dedicated `promos` stream.
final promoServiceProvider = Provider<PromoService>((ref) {
  return PromoService(firestore: ref.watch(firestoreProvider));
});

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  return PromoRepository(ref.watch(promoServiceProvider));
});

/// Realtime stream of active admin promos for the categories page.
final activePromosStreamProvider =
    StreamProvider.autoDispose<List<PromoModel>>((ref) {
  return ref.watch(promoRepositoryProvider).watchActivePromos();
});
