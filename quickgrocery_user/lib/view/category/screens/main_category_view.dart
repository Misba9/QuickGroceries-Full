import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/home_branding.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/app_search_bar.dart';
import 'package:quickgrocery/core/widgets/sticky_search_bar.dart';
import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/category/presentation/widgets/animated_category_card.dart';
import 'package:quickgrocery/view/category/presentation/widgets/featured_products_section.dart';
import 'package:quickgrocery/view/category/presentation/widgets/flash_sale_widget.dart';
import 'package:quickgrocery/view/app_content/models/app_content_config.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_providers.dart';
import 'package:quickgrocery/view/app_content/presentation/widgets/animated_app_heading.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_video_rail.dart';
import 'package:quickgrocery/view/home/presentation/widgets/recommendations_section.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/search/screens/search_screen.dart';

/// Categories discovery screen — premium animated grocery experience.
///
/// Sections (top → bottom):
///   1. Sticky header (greeting + delivery + pinned search)
///   2. Trending categories (horizontal snap carousel)
///   3. Admin video promos (`banners/` MP4) directly above explore grid
///   4. Shop by category grid
///   5. Flash Deals, Popular Near You, Recommended Products
///
/// Everything is realtime — admin changes propagate instantly via the
/// existing Firestore stream providers.
class MainCategoryViewScreen extends ConsumerStatefulWidget {
  const MainCategoryViewScreen({super.key});

  @override
  ConsumerState<MainCategoryViewScreen> createState() =>
      _MainCategoryViewScreenState();
}

class _MainCategoryViewScreenState
    extends ConsumerState<MainCategoryViewScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    ref.invalidate(categoriesStreamProvider);
    ref.invalidate(bannersStreamProvider);
    ref.invalidate(trendingProductsStreamProvider);
    ref.invalidate(featuredProductsStreamProvider);
    ref.invalidate(appContentStreamProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final gutter = responsive.gutter();
    final appContentAsync = ref.watch(appContentStreamProvider);
    final appContent = appContentAsync.value ?? AppContentConfig.defaults;
    final contentLoading =
        appContentAsync.isLoading && !appContentAsync.hasValue;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        legacy.Provider.of<HomeProvider>(
          context,
          listen: false,
        ).onSelectedChange(0);
      },
      child: Scaffold(
        backgroundColor: AppSurface.background,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              RefreshIndicator(
                color: AppColor.primary,
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    StickySearchBar.asSliver(
                      gutter: gutter,
                      topPadding: 12,
                      bottomPadding: 10,
                      topContentHeight: 44,
                      gap: 8,
                      topContent: const _Greeting(),
                      searchBar: AppSearchBar(
                        hints: [
                          'search_hint_milk'.tr(),
                          'search_hint_bread'.tr(),
                          'search_hint_snacks'.tr(),
                          'search_hint_fruits'.tr(),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchScreen(),
                          ),
                        ),
                      ),
                    ),
                    if (appContent.showTrendingCategories)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(gutter, 2, gutter, 4),
                          child: _TrendingCategoriesSection(
                            heading: appContent.trendingHeading,
                            headingLoading: contentLoading,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 6),
                        child: HomeBannerVideoRail(
                          title: 'category_promo_video_title'.tr(),
                          snapPaging: true,
                        ),
                      ),
                    ),
                    if (appContent.showShopCategory)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(gutter, 2, gutter, 0),
                          child: _AllCategoriesSection(
                            heading: appContent.shopCategoryHeading,
                            headingLoading: contentLoading,
                          ),
                        ),
                      ),
                    if (appContent.showFlashDeals)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 0),
                          child: FlashSaleWidget(
                            cardMargin: EdgeInsets.zero,
                            heading: appContent.flashDealHeading,
                            headingLoading: contentLoading,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
                        child: FeaturedProductsSection(
                          title: 'popular_near_you'.tr(),
                          subtitle: 'popular_near_you_sub'.tr(),
                          icon: Icons.near_me_rounded,
                          provider: trendingProductsStreamProvider,
                          maxItems: 14,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 2, gutter, 0),
                        child: RecommendationsSection(
                          maxItems: 14,
                          sectionTitle: 'recommended_products'.tr(),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 110),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Greeting row (collapses when search bar pins) ───────────────────────

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressService = legacy.Provider.of<AddressService>(context);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categoryCount = (categoriesAsync.value ?? const []).length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppGradients.brand(),
            shape: BoxShape.circle,
            boxShadow: AppShadow.primaryGlow,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.shopping_basket_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedAppGreeting(
                text: HomeBranding.tagline,
                isLoading: false,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppSurface.textMuted,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppSurface.text,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      addressService.address.isEmpty ||
                              addressService.address == 'Loading...'
                          ? 'pick_address_short'.tr()
                          : addressService.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppSurface.text,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (categoryCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: AppColor.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              '$categoryCount ${'categories_pill'.tr()}',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppSurface.text,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Trending categories rail ────────────────────────────────────────────

Map<String, int> _countsByNormalizedCategory(List<ProductModel> products) {
  final out = <String, int>{};
  for (final p in products) {
    final k = p.category.trim().toLowerCase();
    if (k.isEmpty) continue;
    out[k] = (out[k] ?? 0) + 1;
  }
  return out;
}

Map<String, int> _maxDiscountByCategory(List<ProductModel> products) {
  final out = <String, int>{};
  for (final p in products) {
    final k = p.category.trim().toLowerCase();
    if (k.isEmpty || !p.hasDiscount) continue;
    final d = p.discountPercent;
    if (d > (out[k] ?? 0)) out[k] = d;
  }
  return out;
}

class _TrendingCategoriesSection extends ConsumerStatefulWidget {
  const _TrendingCategoriesSection({
    required this.heading,
    this.headingLoading = false,
  });

  final String heading;
  final bool headingLoading;

  @override
  ConsumerState<_TrendingCategoriesSection> createState() =>
      _TrendingCategoriesSectionState();
}

class _TrendingCategoriesSectionState
    extends ConsumerState<_TrendingCategoriesSection> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCats = ref.watch(categoriesStreamProvider);
    final cats = asyncCats.value ?? const <CategoryModel>[];

    if (asyncCats.isLoading && cats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: widget.heading,
              icon: Icons.local_fire_department_rounded,
              isLoading: widget.headingLoading,
            ),
            SizedBox(
              height: 178,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.84,
                  child: const Skeleton(radius: 20),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (cats.isEmpty) return const SizedBox.shrink();

    final featured = cats.take(8).toList();

    return legacy.Consumer<CategoryService>(
      builder: (context, cartService, _) {
        final counts = _countsByNormalizedCategory(cartService.allProducts);
        final discs = _maxDiscountByCategory(cartService.allProducts);

        int countFor(CategoryModel c) =>
            counts[c.name.trim().toLowerCase()] ?? 0;

        int discFor(CategoryModel c) =>
            discs[c.name.trim().toLowerCase()] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: widget.heading,
                icon: Icons.local_fire_department_rounded,
                isLoading: widget.headingLoading,
              ),
              SizedBox(
                height: 178,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: featured.length,
                  padEnds: true,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: FadeInRight(
                        from: 12,
                        duration: Duration(milliseconds: 260 + i * 40),
                        child: AnimatedCategoryCard(
                          category: featured[i],
                          variant:
                              AnimatedCategoryCardVariant.trendingHero,
                          heroPrefix: 'trending-',
                          productCount: countFor(featured[i]),
                          topDiscountPercent: discFor(featured[i]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: featured.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lightweight dot pager for snapping category carousel.
class SmoothPageIndicator extends StatelessWidget {
  const SmoothPageIndicator({
    super.key,
    required this.controller,
    required this.count,
  });

  final PageController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final page = controller.hasClients ? (controller.page ?? 0) : 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final distance = (page - i).abs().clamp(0.0, 1.0);
            final wide = distance < 0.5;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: wide ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: wide
                    ? AppColor.primary
                    : AppColor.primary.withValues(alpha: 0.22),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── All categories grid ─────────────────────────────────────────────────

class _AllCategoriesSection extends ConsumerWidget {
  const _AllCategoriesSection({
    required this.heading,
    this.headingLoading = false,
  });

  final String heading;
  final bool headingLoading;

  /// Compute a safe `childAspectRatio` so each tile can fit
  /// image (square via [AspectRatio(1)]) + 6 px gap + 32 px text label.
  ///
  /// Without this the grid overflows on narrow phones — especially with
  /// the 8-column layout on small tablets.
  double _aspectFor(double cellWidth) {
    const labelHeight = 32.0;
    const gap = 6.0;
    final tileHeight = cellWidth + gap + labelHeight;
    return cellWidth / tileHeight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive.of(context);
    final cols = responsive.categoryCols();

    final asyncCats = ref.watch(categoriesStreamProvider);
    final cats = asyncCats.value ?? const <CategoryModel>[];

    Widget grid({required int count, required IndexedWidgetBuilder builder}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final available =
              (constraints.maxWidth - spacing * (cols - 1)) / cols;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: 12,
              childAspectRatio: _aspectFor(available),
            ),
            itemCount: count,
            itemBuilder: builder,
          );
        },
      );
    }

    if (asyncCats.isLoading && cats.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: heading,
            icon: Icons.grid_view_rounded,
            isLoading: headingLoading,
          ),
          grid(
            count: cols * 3,
            builder: (_, __) => const Skeleton(radius: 14),
          ),
        ],
      );
    }
    if (cats.isEmpty) return const SizedBox.shrink();

    return legacy.Consumer<CategoryService>(
      builder: (context, cartService, _) {
        final counts = _countsByNormalizedCategory(cartService.allProducts);
        final discs = _maxDiscountByCategory(cartService.allProducts);
        int countFor(CategoryModel c) =>
            counts[c.name.trim().toLowerCase()] ?? 0;
        int discFor(CategoryModel c) =>
            discs[c.name.trim().toLowerCase()] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: heading,
              icon: Icons.grid_view_rounded,
              isLoading: headingLoading,
            ),
            grid(
              count: cats.length,
              builder: (context, i) => FadeInUp(
                from: 12,
                duration: Duration(milliseconds: 240 + (i % 12) * 30),
                child: AnimatedCategoryCard(
                  category: cats[i],
                  productCount: countFor(cats[i]),
                  topDiscountPercent: discFor(cats[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
