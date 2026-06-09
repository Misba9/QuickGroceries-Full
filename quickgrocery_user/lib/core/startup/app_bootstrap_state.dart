import 'package:firebase_auth/firebase_auth.dart';

import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/models/product.dart';

/// Top-level bootstrap gate consumed by Home, cart overlay, and shell.
enum AppBootstrapStatus {
  loading,
  ready,
  error,
}

/// UI sub-phases while [AppBootstrapStatus.loading].
enum AppBootstrapPhase {
  idle,
  splash,
  loadingHome,
  ready,
  degraded,
  error,
}

/// Cached home payload surfaced instantly on subsequent launches.
class HomeBootstrapSnapshot {
  const HomeBootstrapSnapshot({
    this.banners = const [],
    this.categories = const [],
    this.featured = const [],
    this.offers = const [],
    this.loadedFromDisk = false,
  });

  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<ProductModel> featured;
  final List<OfferBannerModel> offers;
  final bool loadedFromDisk;

  bool get hasContent =>
      banners.isNotEmpty ||
      categories.isNotEmpty ||
      featured.isNotEmpty ||
      offers.isNotEmpty;

  HomeBootstrapSnapshot copyWith({
    List<BannerModel>? banners,
    List<CategoryModel>? categories,
    List<ProductModel>? featured,
    List<OfferBannerModel>? offers,
    bool? loadedFromDisk,
  }) {
    return HomeBootstrapSnapshot(
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      featured: featured ?? this.featured,
      offers: offers ?? this.offers,
      loadedFromDisk: loadedFromDisk ?? this.loadedFromDisk,
    );
  }
}

/// Single source of truth for cold-start readiness.
class AppBootstrapState {
  const AppBootstrapState({
    this.status = AppBootstrapStatus.loading,
    this.phase = AppBootstrapPhase.idle,
    this.user,
    this.needsOnboarding = false,
    this.homeSnapshot = const HomeBootstrapSnapshot(),
    this.loadingMessage = '',
    this.progress = 0,
    this.errorMessage,
    this.isRetrying = false,
  });

  final AppBootstrapStatus status;
  final AppBootstrapPhase phase;
  final User? user;
  final bool needsOnboarding;
  final HomeBootstrapSnapshot homeSnapshot;
  final String loadingMessage;
  final double progress;
  final String? errorMessage;
  final bool isRetrying;

  bool get isComplete =>
      status == AppBootstrapStatus.ready ||
      phase == AppBootstrapPhase.degraded;

  bool get isAuthenticated => user != null;

  static const initial = AppBootstrapState();

  AppBootstrapState copyWith({
    AppBootstrapStatus? status,
    AppBootstrapPhase? phase,
    User? user,
    bool clearUser = false,
    bool? needsOnboarding,
    HomeBootstrapSnapshot? homeSnapshot,
    String? loadingMessage,
    double? progress,
    String? errorMessage,
    bool clearError = false,
    bool? isRetrying,
  }) {
    return AppBootstrapState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      user: clearUser ? null : (user ?? this.user),
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      homeSnapshot: homeSnapshot ?? this.homeSnapshot,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}
