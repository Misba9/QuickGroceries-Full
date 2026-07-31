import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/permissions/app_permission_coordinator.dart';
import 'package:quickgrocery/core/startup/post_home_startup.dart';
import 'package:quickgrocery/core/widgets/sticky_search_bar.dart';
import 'package:quickgrocery/core/widgets/home_section_error_card.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/core/delivery/delivery_zone_lookup.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/home/presentation/providers/explore_products_provider.dart';
import 'package:quickgrocery/view/app_content/models/app_content_config.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_providers.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/flash_sale_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_helpers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_explore_offer_slivers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_categories_rail.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_delivery_header.dart';
import 'package:quickgrocery/view/home/presentation/widgets/fallback_banner_slider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_slider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_section_slot.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/recently_ordered_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/recommendations_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/delivery/domain/delivery_pricing_policy.dart';
import 'package:quickgrocery/view/home/screens/no_serviceable_area_screen.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Home screen — Step 5 premium iteration.
///
/// Sections (top → bottom):
///   1. Pinned delivery header (premium card + actions)
///   2. Search bar (floating pill)
///   3. Banner carousel — section shimmer until ready
///   4. Categories rail — section shimmer until ready
///   5. Featured products — section shimmer until ready
///   6. Offers / explore grid — section shimmer until ready
///   7. Recommended (picked for you) — section shimmer until ready
///   8. Flash / trending / order-again / legacy rails (secondary)
///
/// After Home opens, never restarts the startup category animation.
/// Each section loads independently; Home stays interactive.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _hasInternet = true;
  bool _isServiceable = true;
  bool _isCheckingServiceability = false;
  /// Optimistic true so Home layout paints immediately; refined in background.
  bool _serviceabilityReady = true;
  String? _lastCheckedPinCode;
  String? _lastObservedAddressId;
  String? _lastObservedPin;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bootstrapLegacyServices();
    _scrollController.addListener(_onScroll);
    AppPermissionCoordinator.settledTick.addListener(_onPermissionsSettled);

    // Connectivity + location refinement wait until Home has painted.
    if (PostHomeStartup.homeVisible.value) {
      _startBackgroundHomeMonitors();
    } else {
      PostHomeStartup.homeVisible.addListener(_onPostHomeVisible);
    }
  }

  void _onPostHomeVisible() {
    if (!PostHomeStartup.homeVisible.value) return;
    PostHomeStartup.homeVisible.removeListener(_onPostHomeVisible);
    _startBackgroundHomeMonitors();
  }

  void _startBackgroundHomeMonitors() {
    _setupConnectivityListener();
    unawaited(_checkConnectivity());
    unawaited(_checkServiceability(force: true));
  }

  void _onPermissionsSettled() {
    if (!mounted) return;
    unawaited(_checkServiceability(force: true));
  }

  void _bootstrapLegacyServices() {
    final addressService = legacy.Provider.of<AddressService>(
      context,
      listen: false,
    );

    addressService.addListener(_onAddressChanged);
    Future.microtask(() async {
      await addressService.ready;
      if (!mounted) return;

      // Paint home immediately when a recent serviceability result is cached.
      if (addressService.shouldBypassServiceAreaCheck) {
        _applyServiceableState(
          addressService,
          serviceable: true,
          pin: addressService.activeDeliveryPin,
        );
      }

      // Address hydrate is fine async — Home already painted optimistically.
      await addressService.getAddress();
      if (!mounted) return;
      if (PostHomeStartup.homeVisible.value) {
        await _checkServiceability(force: true);
      }
    });
  }

  void _applyServiceableState(
    AddressService addressService, {
    required bool serviceable,
    String? pin,
  }) {
    if (!mounted) return;
    final nextPin = pin ?? addressService.pinCode;
    final nextObservedPin = addressService.activeDeliveryPin;
    final nextAddressId = addressService.selectedAddressId;
    final unchanged = _isServiceable == serviceable &&
        _serviceabilityReady &&
        !_isCheckingServiceability &&
        _lastCheckedPinCode == nextPin &&
        _lastObservedPin == nextObservedPin &&
        _lastObservedAddressId == nextAddressId;
    _isCheckingServiceability = false;
    _lastCheckedPinCode = nextPin;
    _lastObservedPin = nextObservedPin;
    _lastObservedAddressId = nextAddressId;
    if (unchanged) return;
    // Only rebuild when the visible branch (serviceable / ready) changes.
    if (_isServiceable == serviceable && _serviceabilityReady) return;
    setState(() {
      _isServiceable = serviceable;
      _serviceabilityReady = true;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(exploreProductsProvider.notifier).loadNextPage();
    }
  }

  void _onAddressChanged() {
    if (_isCheckingServiceability) return;

    final addressService = legacy.Provider.of<AddressService>(
      context,
      listen: false,
    );

    final pin = addressService.activeDeliveryPin;
    final addressId = addressService.selectedAddressId;
    final pinUnchanged = pin == _lastObservedPin;
    final idUnchanged = addressId == _lastObservedAddressId;
    if (pinUnchanged && idUnchanged) return;

    _lastObservedPin = pin;
    _lastObservedAddressId = addressId;

    _checkServiceability(force: true);
  }

  Future<void> _checkServiceability({bool force = false}) async {
    if (!mounted || _isCheckingServiceability) return;

    final addressService = legacy.Provider.of<AddressService>(
      context,
      listen: false,
    );
    var pinCode = addressService.activeDeliveryPin;

    if (!force && pinCode == _lastCheckedPinCode) return;

    setState(() => _isCheckingServiceability = true);

    try {
      final deliveryZoneService = legacy.Provider.of<DeliveryZoneService>(
        context,
        listen: false,
      );
      deliveryZoneService.invalidateCache();

      if (pinCode == null || pinCode.isEmpty) {
        final hasZones = await deliveryZoneService.hasActiveDeliveryZones();
        if (!mounted) return;

        if (!hasZones) {
          await addressService.markAddressValidated(
            serviceable: true,
            addressId: addressService.selectedAddressId,
            pinCode: pinCode,
          );
          _applyServiceableState(
            addressService,
            serviceable: true,
            pin: pinCode,
          );
          return;
        }

        if (addressService.hasSavedAddresses || addressService.latLng != null) {
          _applyServiceableState(
            addressService,
            serviceable: false,
            pin: pinCode,
          );
          return;
        }

        // Wait for post-launch permission prompts to finish before GPS.
        if (!AppPermissionCoordinator.hasSettled) {
          if (!mounted) return;
          _applyServiceableState(
            addressService,
            serviceable: true,
            pin: pinCode,
          );
          return;
        }

        if (!await AppPermissionCoordinator.isLocationGranted()) {
          if (!mounted) return;
          _applyServiceableState(
            addressService,
            serviceable: true,
            pin: pinCode,
          );
          return;
        }

        if (!mounted) return;
        await addressService.getCurrentLocation(context, force: true);
        if (!mounted) return;

        pinCode = addressService.activeDeliveryPin;
        if (pinCode == null || pinCode.isEmpty) {
          // GPS denied, disabled, or reverse-geocode failed — stop spinner.
          _applyServiceableState(
            addressService,
            serviceable: false,
            pin: pinCode,
          );
          return;
        }
      }

      final result = await deliveryZoneService.checkPinCode(pinCode);

      if (!mounted) return;

      final serviceable = switch (result) {
        DeliveryZoneCheckResult.serviceable => true,
        DeliveryZoneCheckResult.noZonesConfigured => true,
        DeliveryZoneCheckResult.notServiceable => false,
        DeliveryZoneCheckResult.missingPin => false,
        DeliveryZoneCheckResult.lookupFailed =>
          addressService.hasValidatedServiceablePin(pinCode),
      };

      await addressService.markAddressValidated(
        serviceable: serviceable,
        addressId: addressService.selectedAddressId,
        pinCode: pinCode,
      );
      if (!mounted) return;
      _applyServiceableState(
        addressService,
        serviceable: serviceable,
        pin: pinCode,
      );
    } catch (e, st) {
      debugPrint('HomeScreen serviceability check failed: $e\n$st');
      if (!mounted) return;
      _applyServiceableState(
        addressService,
        serviceable: addressService.hasValidatedServiceablePin(pinCode),
        pin: pinCode,
      );
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final ok = result.any((r) => r != ConnectivityResult.none);
    if (!mounted || ok == _hasInternet) return;
    setState(() => _hasInternet = ok);
  }

  void _setupConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final ok = results.any((r) => r != ConnectivityResult.none);
      if (!mounted || ok == _hasInternet) return;
      setState(() => _hasInternet = ok);
    });
  }

  Future<void> _refreshAll() async {
    ref.invalidate(categoriesStreamProvider);
    ref.invalidate(bannersStreamProvider);
    ref.invalidate(homeExploreOfferBannersProvider);
    ref.invalidate(trendingProductsStreamProvider);
    ref.invalidate(featuredProductsStreamProvider);
    ref.invalidate(appContentStreamProvider);
    await ref.read(exploreProductsProvider.notifier).refresh();

    if (!mounted) return;
    final categoryService = legacy.Provider.of<CategoryService>(
      context,
      listen: false,
    );
    final homeProvider = legacy.Provider.of<HomeProvider>(
      context,
      listen: false,
    );
    await Future.wait([
      categoryService.fetchProducts(),
      homeProvider.getCustomer(),
      homeProvider.getStatus(),
    ]);
  }

  @override
  void dispose() {
    PostHomeStartup.homeVisible.removeListener(_onPostHomeVisible);
    AppPermissionCoordinator.settledTick.removeListener(_onPermissionsSettled);
    _connectivitySub?.cancel();
    _scrollController.dispose();
    if (mounted) {
      legacy.Provider.of<AddressService>(
        context,
        listen: false,
      ).removeListener(_onAddressChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Never block the whole Home with a full-page shimmer / category loop.
    if (!_isServiceable && _serviceabilityReady) {
      return const NoServiceableAreaScreen();
    }
    if (!_hasInternet) return _OfflineView(onRetry: _checkConnectivity);

    final responsive = Responsive.of(context);
    final gutter = responsive.gutter();

    // Root watches nothing section-specific — leaf Consumers own their data.
    return Scaffold(
      backgroundColor: AppSurface.of(context).background,
      // Top inset comes from LandingScreen's SafeArea only.
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          color: AppColor.primary,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: HomeStickyDeliveryHeaderDelegate(gutter: gutter),
              ),
              StickySearchBar.tappableSliver(
                gutter: gutter,
                hints: const [
                  'Search "milk"',
                  'Search "bread"',
                  'Search "snacks"',
                  'Search "fruits"',
                ],
                onTap: () => Navigator.push(context, AppPageRoutes.search()),
              ),
              _HomePricingSliver(gutter: gutter),
              // 1) Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
                  child: const _BannersSection(),
                ),
              ),
              // 2) Categories
              _HomeCategoriesSliver(gutter: gutter),
              // 3) Featured
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _ProductRailSection(
                    title: 'Featured For You',
                    provider: featuredProductsStreamProvider,
                    legacySpecialCat: 'Featured this week',
                  ),
                ),
              ),
              // 4) Offers / explore — own Consumer so pagination ≠ full Home
              _HomeExploreOffersSliver(gutter: gutter),
              // 5) Recommended
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: const RecommendationsSection(),
                ),
              ),
              _HomeFlashSliver(gutter: gutter),
              _HomeTrendingSliver(gutter: gutter),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: const RecentlyOrderedSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _LegacyRail(
                    title: context.l10n.epic_price_drop_items,
                    specialCat: 'Epic price drop items',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _LegacyRail(
                    title: context.l10n.big_deals_on_beauty_products,
                    specialCat: 'Big deals on beauty products',
                  ),
                ),
              ),
              const _HomeBottomSpacerSliver(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Leaf hosts: each watches only the data it needs ──────────────────────

class _HomePricingSliver extends ConsumerWidget {
  const _HomePricingSliver({required this.gutter});
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricingAsync = ref.watch(pricingConfigProvider);
    final pricing = pricingAsync.asData?.value;
    if (pricingAsync.hasError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
          child: HomeSectionErrorCard(
            title: 'Delivery offers unavailable',
            subtitle:
                'Prices and delivery fees may be outdated until we reconnect.',
            onRetry: () => ref.invalidate(pricingConfigProvider),
            minHeight: 108,
          ),
        ),
      );
    }
    if (pricing == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 10),
        child: _DeliveryPromoStrip(pricing: pricing),
      ),
    );
  }
}

class _HomeCategoriesSliver extends ConsumerWidget {
  const _HomeCategoriesSliver({required this.gutter});
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(
      appContentStreamProvider.select(
        (async) {
          final loading = async.isLoading && !async.hasValue;
          final cfg = async.value ?? AppContentConfig.defaults;
          return loading || cfg.showShopCategory;
        },
      ),
    );
    if (!show) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: const HomeCategoriesRail(),
      ),
    );
  }
}

class _HomeExploreOffersSliver extends ConsumerWidget {
  const _HomeExploreOffersSliver({required this.gutter});
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exploreAsync = ref.watch(exploreProductsProvider);
    final offersAsync = ref.watch(homeExploreOfferBannersProvider);
    return SliverMainAxisGroup(
      slivers: buildHomeExploreOfferSlivers(
        context: context,
        ref: ref,
        exploreAsync: exploreAsync,
        offers: offersAsync.asData?.value ?? const [],
        offersLoading: offersAsync.isLoading && !offersAsync.hasValue,
        gutter: gutter,
      ),
    );
  }
}

class _HomeFlashSliver extends ConsumerWidget {
  const _HomeFlashSliver({required this.gutter});
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(
      appContentStreamProvider.select((async) {
        final loading = async.isLoading && !async.hasValue;
        final cfg = async.value ?? AppContentConfig.defaults;
        return (show: loading || cfg.showFlashDeals, heading: cfg.flashDealHeading, loading: loading);
      }),
    );
    if (!visible.show) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: FlashSaleSection(
          heading: visible.heading,
          headingLoading: visible.loading,
        ),
      ),
    );
  }
}

class _HomeTrendingSliver extends ConsumerWidget {
  const _HomeTrendingSliver({required this.gutter});
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(
      appContentStreamProvider.select((async) {
        final loading = async.isLoading && !async.hasValue;
        final cfg = async.value ?? AppContentConfig.defaults;
        return (title: cfg.trendingHeading, loading: loading);
      }),
    );
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: _ProductRailSection(
          title: meta.title,
          titleLoading: meta.loading,
          provider: trendingProductsStreamProvider,
          legacySpecialCat: "Today's snacks deals",
        ),
      ),
    );
  }
}

class _HomeBottomSpacerSliver extends ConsumerWidget {
  const _HomeBottomSpacerSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCartItems = ref.watch(
      cartProvider.select((c) => c.items.isNotEmpty),
    );
    return SliverToBoxAdapter(
      child: SizedBox(height: hasCartItems ? 110 : 30),
    );
  }
}

class _DeliveryPromoStrip extends StatelessWidget {
  const _DeliveryPromoStrip({required this.pricing});

  final PricingConfig pricing;

  @override
  Widget build(BuildContext context) {
    final message = DeliveryPricingPolicy.homePromoLine(pricing);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppSurface.of(context).card,
        border: Border.all(color: AppSurface.of(context).border),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppSurface.of(context).textPrimary,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  BANNERS SECTION
// ──────────────────────────────────────────────────────────────────────────

class _BannersSection extends ConsumerWidget {
  const _BannersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bannersStreamProvider);
    final loading = async.isLoading && !async.hasValue;
    Widget content;
    if (async.hasError && !async.hasValue) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ref.invalidate(bannersStreamProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry banners'),
            ),
          ),
          const FallbackBannerSlider(),
        ],
      );
    } else {
      final banners = async.asData?.value ?? const <BannerModel>[];
      if (banners.isEmpty && !loading) {
        content = const FallbackBannerSlider();
      } else {
        final carousel = imageCarouselBanners(banners);
        content = carousel.isEmpty
            ? const FallbackBannerSlider()
            : HomeBannerSlider(banners: carousel);
      }
    }

    return HomeSectionSlot(
      loading: loading,
      shimmer: AppLoading.banner,
      minHeight: 160,
      child: content,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  PRODUCT RAILS — new (trending/featured) with legacy fallback
// ──────────────────────────────────────────────────────────────────────────

class _ProductRailSection extends ConsumerWidget {
  const _ProductRailSection({
    required this.title,
    required this.provider,
    required this.legacySpecialCat,
    this.titleLoading = false,
  });

  final String title;
  final bool titleLoading;
  final AutoDisposeStreamProvider<List<ProductModel>> provider;
  final String legacySpecialCat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    final loading = async.isLoading && !async.hasValue;
    if (async.hasError && !async.hasValue) {
      return HomeSectionErrorCard(
        title: 'Unable to load products',
        subtitle: 'Pull to refresh or try again in a moment.',
        onRetry: () => ref.invalidate(provider),
      );
    }

    final products = async.asData?.value ?? const <ProductModel>[];
    final Widget body;
    if (products.isNotEmpty) {
      body = _RailWithProducts(
        title: title,
        titleLoading: titleLoading,
        products: products,
      );
    } else if (!loading) {
      body = _LegacyRail(
        title: title,
        titleLoading: titleLoading,
        specialCat: legacySpecialCat,
      );
    } else {
      body = const SizedBox.shrink();
    }

    return HomeSectionSlot(
      loading: loading,
      minHeight: 240,
      shimmer: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title, isLoading: titleLoading),
            AppLoading.productRail,
          ],
        ),
      ),
      child: body,
    );
  }
}

class _LegacyRail extends ConsumerWidget {
  const _LegacyRail({
    required this.title,
    required this.specialCat,
    this.titleLoading = false,
  });

  final String title;
  final bool titleLoading;
  final String specialCat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(specialCatProductsProvider(specialCat));
    final loading = async.isLoading && !async.hasValue;
    if (async.hasError && !async.hasValue) {
      return const SizedBox.shrink();
    }
    final products = async.asData?.value ?? const <ProductModel>[];
    return HomeSectionSlot(
      loading: loading,
      hideWhenEmpty: true,
      isEmpty: products.isEmpty,
      minHeight: 240,
      shimmer: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title, isLoading: titleLoading),
            AppLoading.productRail,
          ],
        ),
      ),
      child: _RailWithProducts(
        title: title,
        titleLoading: titleLoading,
        products: products,
      ),
    );
  }
}

class _RailWithProducts extends StatelessWidget {
  const _RailWithProducts({
    required this.title,
    required this.products,
    this.titleLoading = false,
  });

  final String title;
  final bool titleLoading;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final h = Responsive.horizontalProductRailHeight(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, isLoading: titleLoading),
          HorizontalProductRail(
            height: h,
            itemExtent: HomeProductCard.railExtent,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = products[i];
              return HomeProductCard(
                key: ValueKey('rail-${p.id}-$title'),
                product: p,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  STATUS / GLOBAL OVERLAYS
// ──────────────────────────────────────────────────────────────────────────

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.of(context).scaffold,
      body: SafeArea(
        top: false,
        bottom: false,
        child: OfflineLoadingView(
          onRetry: onRetry,
        ),
      ),
    );
  }
}
