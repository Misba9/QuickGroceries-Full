import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/app_search_bar.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/home/presentation/providers/explore_products_provider.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/flash_sale_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_helpers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_video_rail.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_categories_rail.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_delivery_header.dart';
import 'package:quickgrocery/view/home/presentation/widgets/fallback_banner_slider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_slider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_status_views.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/recently_ordered_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/recommendations_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/home/screens/no_serviceable_area_screen.dart';
import 'package:quickgrocery/view/search/screens/search_screen.dart';

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
  String? _lastCheckedPinCode;

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
    final homeProvider = legacy.Provider.of<HomeProvider>(
      context,
      listen: false,
    );
    final addressService = legacy.Provider.of<AddressService>(
      context,
      listen: false,
    );
    final categoryService = legacy.Provider.of<CategoryService>(
      context,
      listen: false,
    );

    homeProvider.getCustomer();
    homeProvider.updateAdminFcmToken();
    homeProvider.getStatus();
    categoryService.fetchProducts();

    addressService.addListener(_onAddressChanged);
    addressService.getCurrentLocation(context);

    Future.delayed(const Duration(seconds: 2), _checkServiceability);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      ref.read(exploreProductsProvider.notifier).loadNextPage();
    }
  }

  void _onAddressChanged() {
    if (!_isCheckingServiceability) _checkServiceability();
  }

  Future<void> _checkServiceability() async {
    if (!mounted || _isCheckingServiceability) return;

    final addressService = legacy.Provider.of<AddressService>(
      context,
      listen: false,
    );
    final pinCode = addressService.pinCode;

    if (pinCode == _lastCheckedPinCode) return;

    if (pinCode == null || pinCode.isEmpty) {
      setState(() {
        _isServiceable = true;
        _isCheckingServiceability = false;
        _lastCheckedPinCode = pinCode;
      });
      return;
    }

    setState(() => _isCheckingServiceability = true);

    final deliveryZoneService = legacy.Provider.of<DeliveryZoneService>(
      context,
      listen: false,
    );
    final ok = await deliveryZoneService.isPinCodeServiceable(pinCode);

    if (!mounted) return;
    setState(() {
      _isServiceable = ok;
      _isCheckingServiceability = false;
      _lastCheckedPinCode = pinCode;
    });
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
    ref.invalidate(trendingProductsStreamProvider);
    ref.invalidate(featuredProductsStreamProvider);
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
    if (_isCheckingServiceability) return const _ServiceabilityLoading();
    if (!_isServiceable) return const NoServiceableAreaScreen();
    if (!_hasInternet) return _OfflineView(onRetry: _checkConnectivity);

    final cartService = legacy.Provider.of<CategoryService>(context);
    final hasCartItems = cartService.selectedProduct.isNotEmpty;
    final responsive = Responsive.of(context);
    final gutter = responsive.gutter();

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
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 14),
                  child: AppSearchBar(
                    hints: const [
                      'Search "milk"',
                      'Search "bread"',
                      'Search "snacks"',
                      'Search "fruits"',
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
                  child: const _BannersSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: const HomeCategoriesRail(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 8),
                  child: const HomeBannerVideoRail(
                    segmentCount: 2,
                    segmentIndex: 0,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: const FlashSaleSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _ProductRailSection(
                    title: 'Trending Now',
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
                  padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 8),
                  child: const HomeBannerVideoRail(
                    title: 'More for you',
                    segmentCount: 2,
                    segmentIndex: 1,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _LegacyRail(
                    title: 'epic_price_drop_items'.tr(),
                    specialCat: 'Epic price drop items',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: _LegacyRail(
                    title: 'big_deals_on_beauty_products'.tr(),
                    specialCat: 'Big deals on beauty products',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
                  child: SectionHeader(title: 'explore_products'.tr()),
                ),
              ),
              const _ExploreGridSliver(),
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
      // On error we still show the branded fallback so the home page never
      // looks broken — the error will surface in logs / Crashlytics.
      error: (e, _) => const FallbackBannerSlider(),
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
  });

  final String title;
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
            SectionHeader(title: title),
            Builder(
              builder: (context) => HomeShimmer.horizontalProducts(
                height: Responsive.horizontalProductRailHeight(context),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (products) {
        if (products.isNotEmpty) {
          return _RailWithProducts(title: title, products: products);
        }
        return _LegacyRail(title: title, specialCat: legacySpecialCat);
      },
    );
  }
}

class _LegacyRail extends ConsumerWidget {
  const _LegacyRail({required this.title, required this.specialCat});

  final String title;
  final String specialCat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(specialCatProductsProvider(specialCat));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return _RailWithProducts(title: title, products: products);
      },
    );
  }
}

class _RailWithProducts extends StatelessWidget {
  const _RailWithProducts({required this.title, required this.products});

  final String title;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final h = Responsive.horizontalProductRailHeight(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
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
//  EXPLORE GRID (paginated, responsive cols)
// ──────────────────────────────────────────────────────────────────────────

class _ExploreGridSliver extends ConsumerWidget {
  const _ExploreGridSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exploreProductsProvider);
    final responsive = Responsive.of(context);
    final cols = responsive.cols(phone: 2, tablet: 3, desktop: 4);
    final gutter = responsive.gutter();

    return async.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: HomeShimmer.exploreGrid(),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 16),
          child: HomeErrorView(
            message: 'Couldn\'t load products',
            onRetry: () =>
                ref.read(exploreProductsProvider.notifier).refresh(),
          ),
        ),
      ),
      data: (state) {
        if (state.products.isEmpty) {
          final subtitle = _exploreEmptySubtitle(state);
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 16),
              child: HomeEmptyView(
                message: 'No products available right now.',
                subtitle: subtitle,
                icon: Icons.shopping_bag_outlined,
                height: subtitle == null ? 120 : 156,
              ),
            ),
          );
        }
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              // Slightly taller cells on narrow phones so text + controls
              // stay comfortable even with large accessibility text.
              childAspectRatio: cols >= 4 ? 0.62 : 0.56,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (i >= state.products.length) {
                  return state.isLoadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const SizedBox.shrink();
                }
                return HomeProductCard(product: state.products[i]);
              },
              childCount:
                  state.products.length + (state.isLoadingMore ? cols : 0),
            ),
          ),
        );
      },
    );
  }
}

/// Lightweight, user-friendly subtitle when explore has 0 items.
/// Uses the diagnostic counters carried in [ExploreState] but stays
/// production-safe (no debug-only language).
String? _exploreEmptySubtitle(ExploreState state) {
  if (state.diagnosticRawDocs == 0) return null;
  if (state.diagnosticFilteredUnavailable > 0) {
    return '${state.diagnosticFilteredUnavailable} item(s) are temporarily '
        'out of stock. Pull to refresh.';
  }
  return null;
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
              Text('checking_service_availability'.tr()),
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
