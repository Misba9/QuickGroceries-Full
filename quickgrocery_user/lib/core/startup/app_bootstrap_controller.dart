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
  /// Fast path: disk cache → [ready] immediately; network deferred until Home.
  /// Cold path: still [ready] with empty snapshot — Home streams + post-Home
  /// fetch populate rails (no Firestore before Home mounts).
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
      unawaited(_wireCartBridge(deps));

      // Yield so the category splash can paint after disk decode returns.
      await _yieldToNextFrame();

      // Prefer in-memory snapshot (soft logout) then disk cache.
      final existing = state.homeSnapshot.hasContent
          ? state.homeSnapshot
          : diskSnapshot;

      state = state.copyWith(
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
        homeSnapshot: existing,
        clearUser: true,
        needsOnboarding: false,
        progress: 1,
        clearError: true,
      );
      AppStartupLog.milestone(
        existing.hasContent
            ? 'Guest bootstrap ready from cache'
            : 'Guest bootstrap ready — Home will load catalog',
      );

      // Firestore home rails + heavy catalog only after Home paints.
      PostHomeStartup.enqueue(
        () => _refreshHomeAfterPaint(
          deps: deps,
          prefs: prefs,
          precacheImages: precacheImages,
          guest: true,
        ),
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
        PostHomeStartup.enqueue(
          () => _refreshHomeAfterPaint(
            deps: deps,
            prefs: ref.read(sharedPreferencesProvider),
            precacheImages: precacheImages,
            guest: true,
          ),
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
        // Still open Home — streams can recover; avoid blocking on splash.
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.degraded,
          clearUser: true,
          progress: 1,
          errorMessage: e.toString(),
        );
        PostHomeStartup.enqueue(
          () => _refreshHomeAfterPaint(
            deps: deps,
            prefs: ref.read(sharedPreferencesProvider),
            precacheImages: precacheImages,
            guest: true,
          ),
        );
      }
    } finally {
      _runInFlight = false;
    }
  }

  /// Full cold-start sequence for the signed-in path.
  ///
  /// Profile gate uses local cache only (no Firestore). Network hydrate and
  /// home catalog fetch run after Home via [PostHomeStartup].
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

    // Guest → auth (or re-entry): never replay splash once Home was shown.
    final keepHomeVisible = state.isComplete;

    if (keepHomeVisible) {
      state = state.copyWith(
        user: user,
        needsOnboarding: false,
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
        clearError: true,
        progress: 1,
      );
      AppStartupLog.milestone(
        'Auth restored — Home stays ready',
        'uid=${user.uid}',
      );
    } else {
      _tick(BootstrapLoadingMessages.restoringSession, 0.05);
      state = state.copyWith(
        phase: AppBootstrapPhase.splash,
        user: user,
        status: AppBootstrapStatus.loading,
      );
      AppStartupLog.milestone('Auth restored', 'uid=${user.uid}');
    }

    HomeBootstrapSnapshot diskSnapshot = const HomeBootstrapSnapshot();
    var needsOnboarding = false;

    try {
      final prefs = ref.read(sharedPreferencesProvider);

      if (!keepHomeVisible) {
        _tick(BootstrapLoadingMessages.loadingProfile, 0.12);
      }
      // Local-only phase — no Firestore before Home.
      final phase1 = await Future.wait<Object?>([
        HomeDataCache.read(prefs),
        _resolveProfileLocal(user),
        deps.addressService.ready,
      ]);

      diskSnapshot = phase1[0]! as HomeBootstrapSnapshot;
      needsOnboarding = phase1[1]! as bool;

      // Let splash paint while profile/cache work settles (cold path only).
      if (!keepHomeVisible) {
        await _yieldToNextFrame();
      }

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
        // Home is not mounted — do not use PostHomeStartup queue.
        unawaited(_hydrateProfileAfterHome(user));
        return;
      }

      unawaited(_wireCartBridge(deps));

      final existing = state.homeSnapshot.hasContent
          ? state.homeSnapshot
          : diskSnapshot;

      state = state.copyWith(
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
        homeSnapshot: existing,
        needsOnboarding: false,
        progress: 1,
        clearError: true,
      );
      AppStartupLog.milestone(
        existing.hasContent
            ? 'Auth bootstrap ready from cache'
            : 'Auth bootstrap ready — Home will load catalog',
      );

      PostHomeStartup.enqueue(
        () => _refreshHomeAfterPaint(
          deps: deps,
          prefs: prefs,
          precacheImages: precacheImages,
          guest: false,
        ),
      );
      PostHomeStartup.enqueue(() => _hydrateProfileAfterHome(user));
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
        PostHomeStartup.enqueue(
          () => _refreshHomeAfterPaint(
            deps: deps,
            prefs: ref.read(sharedPreferencesProvider),
            precacheImages: precacheImages,
            guest: false,
          ),
        );
        PostHomeStartup.enqueue(() => _hydrateProfileAfterHome(user));
      } else {
        // Open Home anyway — catalog streams recover post-paint.
        state = state.copyWith(
          status: AppBootstrapStatus.ready,
          phase: AppBootstrapPhase.degraded,
          progress: 1,
          errorMessage: e.toString(),
        );
        AppStartupLog.milestone('Bootstrap degraded', e.toString());
        PostHomeStartup.enqueue(
          () => _refreshHomeAfterPaint(
            deps: deps,
            prefs: ref.read(sharedPreferencesProvider),
            precacheImages: precacheImages,
            guest: false,
          ),
        );
        PostHomeStartup.enqueue(() => _hydrateProfileAfterHome(user));
      }
    } finally {
      _runInFlight = false;
    }
  }

  /// Zones, profile — after first home paint.
  /// Full 300-product catalog is scheduled later (+18) so early Home frames
  /// are not competing with a large sanitize/parse burst.
  Future<void> _deferHeavyCatalogLoads(
    BootstrapDependencies deps, {
    required bool guest,
  }) async {
    AppStartupLog.milestone('Deferred catalog loads start');
    final tasks = <Future<void>>[
      deps.deliveryZoneService.fetchDeliveryZones(),
    ];
    if (!guest) {
      tasks.addAll([
        _loadAddress(deps.addressService),
        deps.homeProvider.getCustomer().then((_) {
          AppStartupLog.milestone('Profile loaded (deferred)');
        }),
        deps.homeProvider.getStatus(),
      ]);
    }
    await Future.wait<void>(tasks, eagerError: false);

    // Addon / search catalog — after rails have painted.
    PostHomeStartup.onFrame(18, () {
      unawaited(() async {
        try {
          await deps.categoryService.fetchProducts();
          AppStartupLog.milestone(
            guest
                ? 'Categories loaded (guest, deferred)'
                : 'Categories loaded (deferred)',
          );
        } catch (e) {
          if (kDebugMode) debugPrint('[AppBootstrap] deferred catalog: $e');
        }
      }());
    });

    AppStartupLog.milestone('Deferred catalog loads complete');
  }

  Future<void> _refreshHomeAfterPaint({
    required BootstrapDependencies deps,
    required SharedPreferences prefs,
    BootstrapPrecacheHook? precacheImages,
    required bool guest,
  }) async {
    await _deferHeavyCatalogLoads(deps, guest: guest);

    // Always ensure a network snapshot when cache was empty; otherwise
    // section streams already own live freshness (avoid duplicate GETs).
    if (state.homeSnapshot.hasContent) {
      if (precacheImages != null) {
        final snap = state.homeSnapshot;
        PostHomeStartup.onFrame(10, () {
          unawaited(precacheImages(snap));
        });
      }
      AppStartupLog.milestone(
        'Background home refresh skipped — streams warm',
      );
      return;
    }
    try {
      final fresh = await _fetchHomeSnapshot();
      if (!fresh.hasContent) {
        if (!state.homeSnapshot.hasContent) {
          AppStartupLog.milestone('Post-home home fetch empty');
        }
        return;
      }
      state = state.copyWith(
        homeSnapshot: fresh,
        status: AppBootstrapStatus.ready,
        phase: AppBootstrapPhase.ready,
        clearError: true,
      );
      await HomeDataCache.write(prefs, fresh);
      if (precacheImages != null) {
        final snap = fresh;
        PostHomeStartup.onFrame(10, () {
          unawaited(precacheImages(snap));
        });
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
    // Clear the onboarding gate without forcing a splash replay when the
    // pipeline is already complete (shell swaps straight to Landing).
    if (state.isComplete) {
      state = state.copyWith(
        needsOnboarding: false,
        phase: AppBootstrapPhase.ready,
        status: AppBootstrapStatus.ready,
        progress: 1,
        clearError: true,
      );
      AppStartupLog.milestone('Onboarding complete — Home stays ready');
      return;
    }
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

  /// Local-cache onboarding gate — never touches Firestore (pre-Home).
  Future<bool> _resolveProfileLocal(User user) async {
    final cachedUid = await UserProfileCache.readCachedUid();
    if (cachedUid != null && cachedUid != user.uid) {
      await UserProfileCache.clearOnLogout();
    }

    if (await UserProfileCache.isProfileCompleteCached()) {
      return false;
    }

    final cached = await UserProfileCache.readProfile();
    final name = (cached['name'] ?? '').trim();
    final gender = (cached['gender'] ?? '').trim();
    if (name.isNotEmpty && gender.isNotEmpty) {
      return false;
    }

    // Partial local profile without name/gender → onboarding.
    // Completely empty cache → allow Home; [_hydrateProfileAfterHome] may
    // flip [needsOnboarding] after the network check.
    final hasAnyLocal = name.isNotEmpty ||
        gender.isNotEmpty ||
        (cached['email'] ?? '').trim().isNotEmpty ||
        (cached['phone'] ?? '').trim().isNotEmpty ||
        (cached['image'] ?? '').trim().isNotEmpty;
    return hasAnyLocal && (name.isEmpty || gender.isEmpty);
  }

  /// Network profile hydrate — only after Home (or onboarding) is showing.
  Future<void> _hydrateProfileAfterHome(User user) async {
    try {
      final needsOnboarding = await _resolveProfile(user);
      if (!needsOnboarding) return;
      if (state.needsOnboarding) return;
      state = state.copyWith(needsOnboarding: true);
      AppStartupLog.milestone('Post-home onboarding required');
    } catch (e) {
      if (kDebugMode) debugPrint('[AppBootstrap] post-home profile: $e');
    }
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

    final bannersFuture = bannerRepo.fetchActiveBanners(limit: 8);

    // Top-half Home rails in parallel — fills while Category Animation loops.
    // First-viewport sized limits; remaining items arrive via live streams.
    final results = await Future.wait<List<dynamic>>([
      bannersFuture,
      _safeCategories(categoryRepo),
      productRepo.fetchFeatured(limit: 6),
      bannersFuture.then((b) => _safeOffers(offerRepo, b)),
      productRepo.fetchTrending(limit: 6),
      productRepo.fetchFlashSale(limit: 8),
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
      return await repo.fetchActiveCategories(limit: 20);
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
