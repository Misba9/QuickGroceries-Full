import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/startup/bootstrap_loading_messages.dart';
import 'package:quickgrocery/core/startup/home_data_cache.dart';
import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';
import 'package:quickgrocery/core/user/user_profile_repository.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_bootstrap_state.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/home/data/services/banner_service.dart';
import 'package:quickgrocery/view/home/data/services/category_service.dart';
import 'package:quickgrocery/view/home/data/services/product_service.dart';
import 'package:quickgrocery/view/home/domain/banner_repository.dart';
import 'package:quickgrocery/view/home/domain/category_repository.dart';
import 'package:quickgrocery/view/home/domain/product_repository.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/offers/data/offer_banner_service.dart';
import 'package:quickgrocery/view/offers/domain/offer_banner_repository.dart';

/// Legacy services required for bootstrap — supplied by [AppBootstrapShell].
class BootstrapDependencies {
  const BootstrapDependencies({
    required this.addressService,
    required this.categoryService,
    required this.homeProvider,
    required this.deliveryZoneService,
  });

  final AddressService addressService;
  final CategoryService categoryService;
  final HomeProvider homeProvider;
  final DeliveryZoneService deliveryZoneService;
}

typedef BootstrapPrecacheHook = Future<void> Function(HomeBootstrapSnapshot);

/// Central orchestrator — parallel init, cache-first home, deterministic gates.
class AppBootstrapController extends Notifier<AppBootstrapState> {
  static const _networkTimeout = Duration(seconds: 12);

  bool _runInFlight = false;
  String? _lastBootUid;
  BootstrapDependencies? _lastDeps;
  BootstrapPrecacheHook? _lastPrecacheHook;

  @override
  AppBootstrapState build() => AppBootstrapState.initial;

  bool get isComplete => state.isComplete;

  void _tick(String message, double progress) {
    state = state.copyWith(
      status: AppBootstrapStatus.loading,
      loadingMessage: message,
      progress: progress,
      clearError: true,
    );
  }

  Future<void> retry() async {
    final deps = _lastDeps;
    if (deps == null || _runInFlight) return;
    state = state.copyWith(
      isRetrying: true,
      clearError: true,
      phase: AppBootstrapPhase.splash,
      status: AppBootstrapStatus.loading,
    );
    await runAuthenticated(deps, precacheImages: _lastPrecacheHook);
    state = state.copyWith(isRetrying: false);
  }

  /// Full cold-start sequence for the signed-in path.
  Future<void> runAuthenticated(
    BootstrapDependencies deps, {
    BootstrapPrecacheHook? precacheImages,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_runInFlight && _lastBootUid == user.uid && state.isComplete) return;

    _runInFlight = true;
    _lastBootUid = user.uid;
    _lastDeps = deps;
    if (precacheImages != null) _lastPrecacheHook = precacheImages;

    _tick(BootstrapLoadingMessages.restoringSession, 0.05);
    state = state.copyWith(
      phase: AppBootstrapPhase.splash,
      user: user,
      status: AppBootstrapStatus.loading,
    );
    AppStartupLog.milestone('Auth restored', 'uid=${user.uid}');

    HomeBootstrapSnapshot diskSnapshot = const HomeBootstrapSnapshot();
    var needsOnboarding = false;

    try {
      final prefs = ref.read(sharedPreferencesProvider);

      _tick(BootstrapLoadingMessages.loadingProfile, 0.12);
      final phase1 = await Future.wait<Object?>([
        HomeDataCache.read(prefs),
        _resolveProfile(user),
        deps.addressService.ready,
      ]);

      diskSnapshot = phase1[0]! as HomeBootstrapSnapshot;
      needsOnboarding = phase1[1]! as bool;

      if (diskSnapshot.hasContent) {
        AppStartupLog.milestone(
          'Cache loaded',
          'banners=${diskSnapshot.banners.length} '
          'categories=${diskSnapshot.categories.length}',
        );
        state = state.copyWith(homeSnapshot: diskSnapshot);
      }

      if (needsOnboarding) {
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.ready,
          needsOnboarding: true,
          progress: 1,
        );
        AppStartupLog.milestone('Bootstrap complete', 'onboarding');
        return;
      }

      state = state.copyWith(
        phase: AppBootstrapPhase.loadingHome,
        needsOnboarding: false,
      );

      _tick(BootstrapLoadingMessages.initializingCart, 0.28);

      await Future.wait<void>([
        _wireCartBridge(deps),
        _loadAddress(deps.addressService),
        deps.deliveryZoneService.fetchDeliveryZones(),
        deps.categoryService.fetchProducts().then((_) {
          AppStartupLog.milestone('Categories loaded');
        }),
        deps.homeProvider.getCustomer().then((_) {
          AppStartupLog.milestone('Profile loaded');
        }),
        deps.homeProvider.getStatus(),
        deps.homeProvider.updateAdminFcmToken(),
      ], eagerError: false);

      _tick(BootstrapLoadingMessages.loadingBanners, 0.55);
      final freshHome = await _fetchHomeSnapshot();

      final merged = freshHome.hasContent
          ? freshHome
          : (diskSnapshot.hasContent ? diskSnapshot : freshHome);

      _tick(BootstrapLoadingMessages.precachingImages, 0.85);
      if (precacheImages != null && merged.hasContent) {
        await precacheImages(merged);
      }

      _tick(BootstrapLoadingMessages.almostReady, 0.95);

      if (!merged.hasContent) {
        state = state.copyWith(
          status: AppBootstrapStatus.error,
          phase: AppBootstrapPhase.error,
          errorMessage:
              'We couldn\'t load the store. Check your connection and try again.',
          progress: 0,
        );
        AppStartupLog.milestone('Bootstrap error', 'no cached data');
        return;
      }

      state = state.copyWith(
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
        homeSnapshot: merged,
        progress: 1,
        loadingMessage: BootstrapLoadingMessages.almostReady,
        clearError: true,
      );

      AppStartupLog.milestone(
        'Bootstrap complete',
        'banners=${merged.banners.length} categories=${merged.categories.length} '
        'featured=${merged.featured.length} offers=${merged.offers.length}',
      );

      if (freshHome.hasContent) {
        unawaited(HomeDataCache.write(prefs, freshHome));
      } else {
        unawaited(_refreshHomeInBackground(prefs));
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppBootstrap] failed: $e\n$st');
      }

      if (diskSnapshot.hasContent) {
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.degraded,
          homeSnapshot: diskSnapshot,
          progress: 1,
          errorMessage: e.toString(),
        );
        AppStartupLog.milestone('Bootstrap degraded', 'using cache');
      } else {
        state = state.copyWith(
          status: AppBootstrapStatus.error,
          phase: AppBootstrapPhase.error,
          errorMessage: e.toString(),
          progress: 0,
        );
        AppStartupLog.milestone('Bootstrap error', e.toString());
      }
    } finally {
      _runInFlight = false;
    }
  }

  void markSignedOut() {
    _lastBootUid = null;
    _lastDeps = null;
    _runInFlight = false;
    state = AppBootstrapState.initial;
    AppStartupLog.milestone('Signed out');
  }

  void markOnboardingComplete() {
    state = state.copyWith(
      needsOnboarding: false,
      phase: AppBootstrapPhase.splash,
      status: AppBootstrapStatus.loading,
    );
  }

  Future<void> _refreshHomeInBackground(SharedPreferences prefs) async {
    try {
      final fresh = await _fetchHomeSnapshot();
      if (!fresh.hasContent) return;
      state = state.copyWith(homeSnapshot: fresh);
      await HomeDataCache.write(prefs, fresh);
      AppStartupLog.milestone('Background refresh complete');
    } catch (e) {
      if (kDebugMode) debugPrint('[AppBootstrap] background refresh: $e');
    }
  }

  Future<void> _wireCartBridge(BootstrapDependencies deps) async {
    ref.read(cartProvider);
    ref.read(cartProvider.notifier).attachLegacy(deps.categoryService);
    ref.read(deliveryZoneServiceProvider.notifier).state =
        deps.deliveryZoneService;
    ref.invalidate(zoneDeliveryProvider);
    ref.read(cartBootstrapReadyProvider.notifier).state = true;
    AppStartupLog.milestone('Cart initialized');
  }

  Future<void> _loadAddress(AddressService addressService) async {
    await addressService.ready;
    if (addressService.hasSavedAddresses) {
      await addressService.getAddress();
    }
    AppStartupLog.milestone('Address loaded');
  }

  Future<bool> _resolveProfile(User user) async {
    final repo = UserProfileRepository();

    if (await UserProfileCache.isProfileCompleteCached()) {
      unawaited(repo.hydrateLocal(user.uid).timeout(_networkTimeout));
      return false;
    }

    final cached = await UserProfileCache.readProfile();
    final name = (cached['name'] ?? '').trim();
    final gender = (cached['gender'] ?? '').trim();
    if (name.isNotEmpty && gender.isNotEmpty) {
      unawaited(repo.hydrateLocal(user.uid).timeout(_networkTimeout));
      return false;
    }

    try {
      await repo.hydrateLocal(user.uid).timeout(_networkTimeout);
      final complete =
          await repo.isProfileComplete(user.uid).timeout(_networkTimeout);
      return !complete;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppBootstrap] profile resolve: $e');
      return name.isEmpty || gender.isEmpty;
    }
  }

  Future<HomeBootstrapSnapshot> _fetchHomeSnapshot() async {
    _tick(BootstrapLoadingMessages.loadingProducts, 0.62);

    final firestore = FirebaseFirestore.instance;
    final bannerRepo = BannerRepository(HomeBannerService(firestore: firestore));
    final categoryRepo =
        CategoryRepository(HomeCategoryService(firestore: firestore));
    final productRepo =
        ProductRepository(HomeProductService(firestore: firestore));
    final offerRepo = OfferBannerRepository(
      OfferBannerService(firestore: firestore),
      bannerRepo,
    );

    final banners = await bannerRepo.fetchActiveBanners(limit: 20);
    AppStartupLog.milestone('Banners loaded', 'count=${banners.length}');

    _tick(BootstrapLoadingMessages.loadingOffers, 0.72);

    final results = await Future.wait<List<dynamic>>([
      Future.value(banners),
      _safeCategories(categoryRepo),
      productRepo.fetchFeatured(limit: 12),
      _safeOffers(offerRepo, banners),
    ], eagerError: false);

    AppStartupLog.milestone(
      'Home data fetched',
      'banners=${results[0].length} categories=${results[1].length} '
      'featured=${results[2].length} offers=${results[3].length}',
    );

    return HomeBootstrapSnapshot(
      banners: results[0].cast<BannerModel>(),
      categories: results[1].cast<CategoryModel>(),
      featured: results[2].cast<ProductModel>(),
      offers: results[3].cast<OfferBannerModel>(),
      loadedFromDisk: false,
    );
  }

  Future<List<CategoryModel>> _safeCategories(CategoryRepository repo) async {
    try {
      return await repo.fetchActiveCategories(limit: 40);
    } catch (e) {
      if (kDebugMode) debugPrint('[AppBootstrap] categories: $e');
      return const [];
    }
  }

  Future<List<OfferBannerModel>> _safeOffers(
    OfferBannerRepository offerRepo,
    List<BannerModel> adminBanners,
  ) async {
    try {
      return await offerRepo.fetchHomeExploreOffers(adminBanners: adminBanners);
    } catch (e) {
      if (kDebugMode) debugPrint('[AppBootstrap] offers: $e');
      return const [];
    }
  }
}

final appBootstrapProvider =
    NotifierProvider<AppBootstrapController, AppBootstrapState>(
  AppBootstrapController.new,
);

final appBootstrapCompleteProvider = Provider<bool>((ref) {
  return ref.watch(appBootstrapProvider).isComplete;
});

final homeBootstrapSnapshotProvider = Provider<HomeBootstrapSnapshot>((ref) {
  return ref.watch(appBootstrapProvider).homeSnapshot;
});

final appBootstrapStatusProvider = Provider<AppBootstrapStatus>((ref) {
  return ref.watch(appBootstrapProvider).status;
});
