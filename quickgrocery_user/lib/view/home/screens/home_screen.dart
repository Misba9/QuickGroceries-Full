import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/widgets/sticky_search_bar.dart';
import 'package:quickgrocery/core/widgets/home_section_error_card.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
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
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
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
///   3. Banner carousel (image-only slides; 16:7)
///   4. Categories horizontal rail
///   5. Video promo rail (admin MP4 banners)
///   6. Flash sale (countdown rail)
///   6. Trending Now / Featured For You (Riverpod)
///   7. Picked for you (personalized)
///   8. Order again (recently ordered)
///   9. Legacy `special_cat` rails (auto-hide when empty)
///   10. Explore (paginated grid, responsive cols)
///
/// The floating cart pill lives in [LandingScreen] so it persists across
/// every bottom-nav tab.
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
  bool _serviceabilityReady = false;
  String? _lastCheckedPinCode;
  String? _lastObservedAddressId;
  String? _lastObservedPin;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bootstrapLegacyServices();
    _setupConnectivityListener();
    _checkConnectivity();
    _scrollController.addListener(_onScroll);
  }

  void _bootstrapLegacyServices() {
    final addressService = legacy.Provider.of<AddressService>(
      context,
      listen: false,
    );

    addressService.addListener(_onAddressChanged);
    Future.microtask(() async {
      await addressService.ready;
      await addressService.getAddress();
      if (!mounted) return;

      if (addressService.shouldBypassServiceAreaCheck) {
        _applyServiceableState(
          addressService,
          serviceable: true,
          pin: addressService.activeDeliveryPin,
        );
        return;
      }

      final pin = addressService.activeDeliveryPin;
      if (addressService.hasSavedAddresses && pin != null && pin.isNotEmpty) {
        await _checkServiceability(force: true);
        return;
      }

      if (pin != null && pin.isNotEmpty) {
        await _checkServiceability(force: true);
        return;
      }

      await addressService.getCurrentLocation(context);
      if (!mounted) return;
      await _checkServiceability(force: true);
    });
  }

  void _applyServiceableState(
    AddressService addressService, {
    required bool serviceable,
    String? pin,
  }) {
    if (!mounted) return;
    setState(() {
      _isServiceable = serviceable;
      _serviceabilityReady = true;
      _isCheckingServiceability = false;
      _lastCheckedPinCode = pin ?? addressService.pinCode;
      _lastObservedPin = addressService.activeDeliveryPin;
      _lastObservedAddressId = addressService.selectedAddressId;
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

    if (addressService.shouldBypassServiceAreaCheck) {
      _applyServiceableState(addressService, serviceable: true);
      return;
    }

    final pin = addressService.activeDeliveryPin;
    final addressId = addressService.selectedAddressId;
    final pinUnchanged = pin == _lastObservedPin;
    final idUnchanged = addressId == _lastObservedAddressId;
    if (pinUnchanged && idUnchanged) return;

    _lastObservedPin = pin;
    _lastObservedAddressId = addressId;

    if (addressService.hasValidatedServiceablePin(pin)) {
      _applyServiceableState(addressService, serviceable: true, pin: pin);
      return;
    }

    _checkServiceability(force: true);
  }

  Future<void> _checkServiceability({bool force = false}) async {
    if (!mounted || _isCheckingServiceability) return;

    final addressService = legacy.Provider.of<AddressService>(
      context,
      listen: false,
    );
    final pinCode = addressService.activeDeliveryPin;

    if (addressService.shouldBypassServiceAreaCheck) {
      _applyServiceableState(addressService, serviceable: true, pin: pinCode);
      return;
    }

    if (addressService.hasValidatedServiceablePin(pinCode)) {
      _applyServiceableState(addressService, serviceable: true, pin: pinCode);
      return;
    }

    if (!force && pinCode == _lastCheckedPinCode) return;

    if (pinCode == null || pinCode.isEmpty) {
      _applyServiceableState(addressService, serviceable: true, pin: pinCode);
      return;
    }

    setState(() => _isCheckingServiceability = true);

    final deliveryZoneService = legacy.Provider.of<DeliveryZoneService>(
      context,
      listen: false,
    );
    final ok = await deliveryZoneService.isPinCodeServiceable(pinCode);

    if (!mounted) return;
    if (!ok &&
        deliveryZoneService.lastLookupFailed &&
        addressService.hasValidatedServiceableAddress) {
      _applyServiceableState(addressService, serviceable: true, pin: pinCode);
      return;
    }
    await addressService.markAddressValidated(
      serviceable: ok,
      addressId: addressService.selectedAddressId,
      pinCode: pinCode,
    );
    if (!mounted) return;
    _applyServiceableState(addressService, serviceable: ok, pin: pinCode);
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final ok = result.any((r) => r != ConnectivityResult.none);
    if (mounted) setState(() => _hasInternet = ok);
  }

  void _setupConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final ok = results.any((r) => r != ConnectivityResult.none);
      if (mounted) setState(() => _hasInternet = ok);
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
    final addressService = legacy.Provider.of<AddressService>(context);
    if (addressService.shouldBypassServiceAreaCheck && !_serviceabilityReady) {
      _applyServiceableState(addressService, serviceable: true);
    }

    if (!_serviceabilityReady) {
      return const _ServiceabilityLoading();
    }
    if (!_isServiceable) return const NoServiceableAreaScreen();
    if (!_hasInternet) return _OfflineView(onRetry: _checkConnectivity);

    final cartService = legacy.Provider.of<CategoryService>(context);
    final hasCartItems = cartService.selectedProduct.isNotEmpty;
    final responsive = Responsive.of(context);
    final gutter = responsive.gutter();
    final pricingAsync = ref.watch(pricingConfigProvider);
    final pricing = pricingAsync.asData?.value;
    final appContentAsync = ref.watch(appContentStreamProvider);
    final appContent = appContentAsync.value ?? AppContentConfig.defaults;
    final contentLoading =
        appContentAsync.isLoading && !appContentAsync.hasValue;

    return Scaffold(
      backgroundColor: AppSurface.background,
      body: SafeArea(
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
              if (pricingAsync.hasError)
                SliverToBoxAdapter(
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
                ),
              if (pricing != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 10),
                    child: _DeliveryPromoStrip(pricing: pricing),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
                  child: const _BannersSection(),
                ),
              ),
              if (appContent.showShopCategory)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: const HomeCategoriesRail(),
                  ),
                ),
              if (appContent.showFlashDeals)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: FlashSaleSection(
                      heading: appContent.flashDealHeading,
                      headingLoading: contentLoading,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _ProductRailSection(
                    title: appContent.trendingHeading,
                    titleLoading: contentLoading,
                    provider: trendingProductsStreamProvider,
                    legacySpecialCat: "Today's snacks deals",
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: const RecommendationsSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: const RecentlyOrderedSection(),
                ),
              ),
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
              ...buildHomeExploreOfferSlivers(
                context: context,
                ref: ref,
                exploreAsync: ref.watch(exploreProductsProvider),
                offers:
                    ref.watch(homeExploreOfferBannersProvider).asData?.value ??
                        const [],
                gutter: gutter,
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: hasCartItems ? 110 : 30),
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: AppSurface.border),
      ),
      child: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.w600),
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
    return async.when(
      loading: () => HomeShimmer.banner(),
      error: (e, _) => Column(
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
      ),
      data: (List<BannerModel> banners) {
        if (banners.isEmpty) return const FallbackBannerSlider();
        final carousel = imageCarouselBanners(banners);
        if (carousel.isEmpty) return const FallbackBannerSlider();
        return HomeBannerSlider(banners: carousel);
      },
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

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title, isLoading: titleLoading),
            Builder(
              builder: (context) => HomeShimmer.horizontalProducts(
                height: Responsive.horizontalProductRailHeight(context),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => HomeSectionErrorCard(
        title: 'Unable to load products',
        subtitle: 'Pull to refresh or try again in a moment.',
        onRetry: () => ref.invalidate(provider),
      ),
      data: (products) {
        if (products.isNotEmpty) {
          return _RailWithProducts(
            title: title,
            titleLoading: titleLoading,
            products: products,
          );
        }
        return _LegacyRail(
          title: title,
          titleLoading: titleLoading,
          specialCat: legacySpecialCat,
        );
      },
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
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return _RailWithProducts(
          title: title,
          titleLoading: titleLoading,
          products: products,
        );
      },
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
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => HomeProductCard(product: products[i]),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  STATUS / GLOBAL OVERLAYS
// ──────────────────────────────────────────────────────────────────────────

class _ServiceabilityLoading extends StatelessWidget {
  const _ServiceabilityLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.l10n.checking_service_availability),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'No Internet connection',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your internet connection and try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
