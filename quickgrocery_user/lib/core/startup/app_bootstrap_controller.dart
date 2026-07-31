import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/startup/bootstrap_loading_messages.dart';
import 'package:quickgrocery/core/startup/home_data_cache.dart';
import 'package:quickgrocery/core/startup/post_home_startup.dart';
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

  Future<void> retry({bool guest = false}) async {
    final deps = _lastDeps;
    if (deps == null || _runInFlight) return;
    state = state.copyWith(
      isRetrying: true,
      clearError: true,
      phase: AppBootstrapPhase.splash,
      status: AppBootstrapStatus.loading,
    );
    if (guest) {
      await runGuest(deps, precacheImages: _lastPrecacheHook);
    } else {
      await runAuthenticated(deps, precacheImages: _lastPrecacheHook);
    }
    state = state.copyWith(isRetrying: false);
  }

  /// Cold-start for guest browsing — public catalog only, no user data.
  ///
  /// Fast path: disk cache → [ready] immediately; network + catalog deferred.
  /// Cold path: fetch home rails only (banners/categories/featured/offers).
  Future<void> runGuest(
    BootstrapDependencies deps, {
    BootstrapPrecacheHook? precacheImages,
  }) async {
    if (_runInFlight) return;

    _runInFlight = true;
    _lastBootUid = null;
    _lastDeps = deps;
    if (precacheImages != null) _lastPrecacheHook = precacheImages;

    AppStartupLog.milestone('Guest bootstrap started');

    HomeBootstrapSnapshot diskSnapshot = const HomeBootstrapSnapshot();

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      diskSnapshot = await HomeDataCache.read(prefs);

      // Cart bridge is local — never wait on Firestore catalog/zones.
      // Prefer [CartBootstrap] when it already attached; still ensure zone wiring.
      unawaited(_wireCartBridge(deps));

      // Yield so the category splash can paint after disk decode returns.
      await _yieldToNextFrame();

      // Prefer in-memory snapshot (soft logout) then disk cache — never splash.
      final existing = state.homeSnapshot.hasContent
          ? state.homeSnapshot
          : diskSnapshot;

      if (existing.hasContent) {
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.ready,
          homeSnapshot: existing,
          clearUser: true,
          needsOnboarding: false,
          progress: 1,
          clearError: true,
        );
        AppStartupLog.milestone('Guest bootstrap ready from cache');
        PostHomeStartup.enqueue(
          () => _refreshHomeAfterPaint(
            deps: deps,
            prefs: prefs,
            precacheImages: precacheImages,
            guest: true,
          ),
        );
        return;
      }

      // Cold guest path only when there is no catalog yet.
      _tick(BootstrapLoadingMessages.loadingBanners, 0.2);
      state = state.copyWith(
        phase: AppBootstrapPhase.splash,
        clearUser: true,
        needsOnboarding: false,
        status: AppBootstrapStatus.loading,
      );

      state = state.copyWith(phase: AppBootstrapPhase.loadingHome);
      _tick(BootstrapLoadingMessages.loadingBanners, 0.55);

      final freshHome = await _fetchHomeSnapshot();
      if (!freshHome.hasContent) {
        state = state.copyWith(
          status: AppBootstrapStatus.error,
          phase: AppBootstrapPhase.error,
          errorMessage:
              'We couldn\'t load the store. Check your connection and try again.',
          progress: 0,
        );
        return;
      }

      state = state.copyWith(
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
        homeSnapshot: freshHome,
        progress: 1,
        clearError: true,
      );
      AppStartupLog.milestone('Guest bootstrap complete');

      unawaited(HomeDataCache.write(prefs, freshHome));
      if (precacheImages != null) {
        unawaited(precacheImages(freshHome));
      }
      PostHomeStartup.enqueue(
        () => _deferHeavyCatalogLoads(deps, guest: true),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppBootstrap] guest failed: $e\n$st');
      }

      if (diskSnapshot.hasContent) {
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.degraded,
          homeSnapshot: diskSnapshot,
          progress: 1,
          errorMessage: e.toString(),
        );
      } else if (state.homeSnapshot.hasContent) {
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.degraded,
          clearUser: true,
          progress: 1,
          errorMessage: e.toString(),
        );
      } else {
        state = state.copyWith(
          status: AppBootstrapStatus.error,
          phase: AppBootstrapPhase.error,
          errorMessage: e.toString(),
          progress: 0,
        );
      }
    } finally {
      _runInFlight = false;
    }
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

      // Let splash paint while profile/cache work settles.
      await _yieldToNextFrame();

      if (diskSnapshot.hasContent) {
        AppStartupLog.milestone(
          'Cache loaded',
          'banners=${diskSnapshot.banners.length} '
          'categories=${diskSnapshot.categories.length}',
        );
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

      unawaited(_wireCartBridge(deps));

      if (diskSnapshot.hasContent) {
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.ready,
          homeSnapshot: diskSnapshot,
          needsOnboarding: false,
          progress: 1,
          clearError: true,
        );
        AppStartupLog.milestone('Auth bootstrap ready from cache');
        PostHomeStartup.enqueue(
          () => _refreshHomeAfterPaint(
            deps: deps,
            prefs: prefs,
            precacheImages: precacheImages,
            guest: false,
          ),
        );
        return;
      }

      state = state.copyWith(
        phase: AppBootstrapPhase.loadingHome,
        needsOnboarding: false,
      );
      _tick(BootstrapLoadingMessages.loadingBanners, 0.55);

      final freshHome = await _fetchHomeSnapshot();
      final merged = freshHome.hasContent ? freshHome : diskSnapshot;

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
        'featured=${merged.featured.length} trending=${merged.trending.length} '
        'flash=${merged.flashSale.length} offers=${merged.offers.length} '
        'topHalf=${(merged.topHalfFillRatio * 100).round()}%',
      );

      if (freshHome.hasContent) {
        unawaited(HomeDataCache.write(prefs, freshHome));
      }
      if (precacheImages != null && merged.hasContent) {
        unawaited(precacheImages(merged));
      }
      PostHomeStartup.enqueue(
        () => _deferHeavyCatalogLoads(deps, guest: false),
      );
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

  /// Zones, full product catalog, profile/FCM — after first home paint.
  Future<void> _deferHeavyCatalogLoads(
    BootstrapDependencies deps, {
    required bool guest,
  }) async {
    AppStartupLog.milestone('Deferred catalog loads start');
    final tasks = <Future<void>>[
      deps.deliveryZoneService.fetchDeliveryZones(),
      deps.categoryService.fetchProducts().then((_) {
        AppStartupLog.milestone(
          guest ? 'Categories loaded (guest, deferred)' : 'Categories loaded (deferred)',
        );
      }),
    ];
    if (!guest) {
      tasks.addAll([
        _loadAddress(deps.addressService),
        deps.homeProvider.getCustomer().then((_) {
          AppStartupLog.milestone('Profile loaded (deferred)');
        }),
        deps.homeProvider.getStatus(),
        // FCM token write is owned by [RealtimeBootstrap] — skip duplicate
        // getToken + customers/{uid} merge here.
      ]);
    }
    await Future.wait<void>(tasks, eagerError: false);
    AppStartupLog.milestone('Deferred catalog loads complete');
  }

  Future<void> _refreshHomeAfterPaint({
    required BootstrapDependencies deps,
    required SharedPreferences prefs,
    BootstrapPrecacheHook? precacheImages,
    required bool guest,
  }) async {
    await _deferHeavyCatalogLoads(deps, guest: guest);
    // Section streams (HomeFeedWarmup + home StreamProviders) already own
    // live freshness. A second full catalog GET here duplicated banners /
    // categories / products / offers API work on every warm start.
    if (state.homeSnapshot.hasContent) {
      if (precacheImages != null) {
        unawaited(precacheImages(state.homeSnapshot));
      }
      AppStartupLog.milestone(
        'Background home refresh skipped — streams warm',
      );
      return;
    }
    try {
      final fresh = await _fetchHomeSnapshot();
      if (!fresh.hasContent) return;
      state = state.copyWith(
        homeSnapshot: fresh,
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
      );
      await HomeDataCache.write(prefs, fresh);
      if (precacheImages != null) {
        unawaited(precacheImages(fresh));
      }
      AppStartupLog.milestone('Background home refresh complete');
    } catch (e) {
      if (kDebugMode) debugPrint('[AppBootstrap] background refresh: $e');
    }
  }

  /// Soft logout handoff: clear the signed-in user but keep Home ready when the
  /// public catalog snapshot is already in memory (no splash / loading loop).
  void prepareGuestHandoff() {
    _lastBootUid = null;
    _runInFlight = false;
    if (state.homeSnapshot.hasContent &&
        (state.phase == AppBootstrapPhase.ready ||
            state.phase == AppBootstrapPhase.degraded ||
            state.status == AppBootstrapStatus.ready)) {
      state = state.copyWith(
        clearUser: true,
        needsOnboarding: false,
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
        clearError: true,
        progress: 1,
      );
      AppStartupLog.milestone('Guest handoff — home stays ready');
      return;
    }
    _lastDeps = null;
    state = AppBootstrapState.initial;
    AppStartupLog.milestone('Signed out');
  }

  /// @deprecated Prefer [prepareGuestHandoff] for logout.
  void markSignedOut() => prepareGuestHandoff();

  void markOnboardingComplete() {
    state = state.copyWith(
      needsOnboarding: false,
      phase: AppBootstrapPhase.splash,
      status: AppBootstrapStatus.loading,
    );
  }

  Future<void> _wireCartBridge(BootstrapDependencies deps) async {
    // [CartBootstrap] may already have attached — attachLegacy is idempotent.
    ref.read(cartProvider);
    ref.read(cartProvider.notifier).attachLegacy(deps.categoryService);
    ref.read(deliveryZoneServiceProvider.notifier).state =
        deps.deliveryZoneService;
    if (!ref.read(cartBootstrapReadyProvider)) {
      ref.invalidate(zoneDeliveryProvider);
      ref.read(cartBootstrapReadyProvider.notifier).state = true;
      AppStartupLog.milestone('Cart initialized');
    }
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

    final cachedUid = await UserProfileCache.readCachedUid();
    if (cachedUid != null && cachedUid != user.uid) {
      await UserProfileCache.clearOnLogout();
    }

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

    final bannersFuture = bannerRepo.fetchActiveBanners(limit: 20);

    // Top-half Home rails in parallel — fills while Category Animation loops.
    final results = await Future.wait<List<dynamic>>([
      bannersFuture,
      _safeCategories(categoryRepo),
      productRepo.fetchFeatured(limit: 12),
      bannersFuture.then((b) => _safeOffers(offerRepo, b)),
      productRepo.fetchTrending(limit: 12),
      productRepo.fetchFlashSale(limit: 16),
    ], eagerError: false);

    AppStartupLog.milestone(
      'Home data fetched',
      'banners=${results[0].length} categories=${results[1].length} '
      'featured=${results[2].length} offers=${results[3].length} '
      'trending=${results[4].length} flash=${results[5].length}',
    );

    return HomeBootstrapSnapshot(
      banners: results[0].cast<BannerModel>(),
      categories: results[1].cast<CategoryModel>(),
      featured: results[2].cast<ProductModel>(),
      offers: results[3].cast<OfferBannerModel>(),
      trending: results[4].cast<ProductModel>(),
      flashSale: results[5].cast<ProductModel>(),
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

  /// Yield to the next frame without [Future.delayed] / [Timer].
  static Future<void> _yieldToNextFrame() {
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    SchedulerBinding.instance.scheduleFrame();
    return completer.future;
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
