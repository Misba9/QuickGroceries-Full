import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/data/services/banner_service.dart';
import 'package:quickgrocery/view/home/data/services/category_service.dart';
import 'package:quickgrocery/view/home/data/services/product_service.dart';
import 'package:quickgrocery/view/home/domain/banner_repository.dart';
import 'package:quickgrocery/view/home/domain/category_repository.dart';
import 'package:quickgrocery/view/home/domain/product_repository.dart';

// ── Infrastructure providers ───────────────────────────────────────────────
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ── Service providers ──────────────────────────────────────────────────────
final categoryServiceProvider = Provider<HomeCategoryService>((ref) {
  return HomeCategoryService(firestore: ref.watch(firestoreProvider));
});

final bannerServiceProvider = Provider<HomeBannerService>((ref) {
  return HomeBannerService(firestore: ref.watch(firestoreProvider));
});

final productServiceProvider = Provider<HomeProductService>((ref) {
  return HomeProductService(firestore: ref.watch(firestoreProvider));
});

// ── Repository providers ───────────────────────────────────────────────────
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(categoryServiceProvider));
});

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.watch(bannerServiceProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(productServiceProvider));
});

// ── Stream providers consumed by the homepage ─────────────────────────────
// Bootstrap seed is [ref.read] once — watching the snapshot would dispose and
// re-subscribe every time bootstrap replaces the snapshot instance.
final categoriesStreamProvider =
    StreamProvider.autoDispose<List<CategoryModel>>((ref) async* {
      final seed = ref.read(homeBootstrapSnapshotProvider).categories;
      if (seed.isNotEmpty) yield seed;
      yield* ref.watch(categoryRepositoryProvider).watchActiveCategories();
    });

final bannersStreamProvider =
    StreamProvider.autoDispose<List<BannerModel>>((ref) async* {
      final seed = ref.read(homeBootstrapSnapshotProvider).banners;
      if (seed.isNotEmpty) yield seed;
      yield* ref.watch(bannerRepositoryProvider).watchActiveBanners();
    });

final trendingProductsStreamProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) async* {
      final seed = ref.read(homeBootstrapSnapshotProvider).trending;
      if (seed.isNotEmpty) yield seed;
      yield* ref.watch(productRepositoryProvider).watchTrending(limit: 8);
    });

final featuredProductsStreamProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) async* {
      final seed = ref.read(homeBootstrapSnapshotProvider).featured;
      if (seed.isNotEmpty) yield seed;
      yield* ref.watch(productRepositoryProvider).watchFeatured(limit: 8);
    });

final flashSaleProductsStreamProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) async* {
      final seed = ref.read(homeBootstrapSnapshotProvider).flashSale;
      if (seed.isNotEmpty) yield seed;
      yield* ref.watch(productRepositoryProvider).watchFlashSale(limit: 10);
    });

/// Family stream for the legacy `special_cat` rails so a single provider
/// definition powers all four legacy sections.
final specialCatProductsProvider = StreamProvider.autoDispose
    .family<List<ProductModel>, String>((ref, specialCat) {
      return ref
          .watch(productRepositoryProvider)
          .watchBySpecialCat(specialCat, limit: 20);
    });
