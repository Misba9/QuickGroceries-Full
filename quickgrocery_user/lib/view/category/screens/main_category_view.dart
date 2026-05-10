import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/app_search_bar.dart';
import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/category/presentation/providers/categories_discovery_providers.dart';
import 'package:quickgrocery/view/category/presentation/widgets/animated_category_card.dart';
import 'package:quickgrocery/view/category/presentation/widgets/featured_products_section.dart';
import 'package:quickgrocery/view/category/presentation/widgets/flash_sale_widget.dart';
import 'package:quickgrocery/view/category/presentation/widgets/floating_cart_bar.dart';
import 'package:quickgrocery/view/category/presentation/widgets/hero_banner_slider.dart';
import 'package:quickgrocery/view/category/presentation/widgets/promo_video_section.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_video_rail.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/search/screens/search_screen.dart';

/// Categories discovery screen — premium animated grocery experience.
///
/// Sections (top → bottom):
///   1. Animated header (greeting + delivery location + categories count)
///   2. Sticky search bar (cycling hints + voice mic)
///   3. Hero banner carousel (Firestore `banners/`, falls back to branded slides)
///   4. Trending categories rail (gradient hero cards)
///   5. Promo videos / GIFs / Lottie offers (Firestore `promos/`)
///   6. All categories grid (responsive 4 / 6 / 8 columns, staggered fade-in)
///   7. Flash sale (countdown + glowing cards) — pulled from products with
///      ≥25 % discount in trending + featured streams
///   8. Featured for you (Firestore `products` where `isFeatured == true`)
///   9. Trending now    (Firestore `products` where `isTrending == true`)
///   10. Floating cart bar (auto-shows when cart has items)
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
  bool _condenseHeader = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final condense = _scrollController.offset > 60;
    if (condense != _condenseHeader && mounted) {
      setState(() => _condenseHeader = condense);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    ref.invalidate(categoriesStreamProvider);
    ref.invalidate(bannersStreamProvider);
    ref.invalidate(activePromosStreamProvider);
    ref.invalidate(trendingProductsStreamProvider);
    ref.invalidate(featuredProductsStreamProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final gutter = responsive.gutter();

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
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyHeaderDelegate(
                        condense: _condenseHeader,
                        gutter: gutter,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 12),
                        child: const HeroBannerSlider(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 10),
                        child: const HomeBannerVideoRail(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
                        child: const _TrendingCategoriesSection(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              title: 'offers_for_you'.tr(),
                              icon: Icons.local_offer_rounded,
                            ),
                            const PromoVideoSection(),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
                        child: const _AllCategoriesSection(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
                        child: const FlashSaleWidget(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
                        child: FeaturedProductsSection(
                          title: 'featured_for_you'.tr(),
                          subtitle: 'curated_picks_subtitle'.tr(),
                          icon: Icons.auto_awesome_rounded,
                          provider: featuredProductsStreamProvider,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
                        child: FeaturedProductsSection(
                          title: 'trending_now'.tr(),
                          subtitle: 'trending_subtitle'.tr(),
                          icon: Icons.trending_up_rounded,
                          provider: trendingProductsStreamProvider,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
                        child: FeaturedProductsSection(
                          title: 'best_sellers'.tr(),
                          subtitle: 'best_sellers_subtitle'.tr(),
                          icon: Icons.workspace_premium_rounded,
                          provider: trendingProductsStreamProvider,
                          maxItems: 12,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 110),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: FloatingCartBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sticky animated header ──────────────────────────────────────────────

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.condense,
    required this.gutter,
  });

  final bool condense;
  final double gutter;

  static const double _expanded = 168;
  static const double _collapsed = 76;

  @override
  double get minExtent => _collapsed;
  @override
  double get maxExtent => _expanded;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final greetingOpacity = (1 - t * 1.6).clamp(0.0, 1.0);
    final searchTop = 64.0 - (t * 18);

    return Material(
      color: AppSurface.background,
      elevation: t * 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          color: AppSurface.background,
          border: Border(
            bottom: BorderSide(
              color: AppSurface.border.withValues(alpha: t),
              width: 0.6,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: gutter,
              right: gutter,
              top: 12,
              child: Opacity(
                opacity: greetingOpacity,
                child: const _Greeting(),
              ),
            ),
            Positioned(
              left: gutter,
              right: gutter,
              top: searchTop,
              child: AppSearchBar(
                hints: [
                  'search_hint_milk'.tr(),
                  'search_hint_bread'.tr(),
                  'search_hint_snacks'.tr(),
                  'search_hint_fruits'.tr(),
                ],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.condense != condense || oldDelegate.gutter != gutter;
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  String _greetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return 'good_morning'.tr();
    if (h < 17) return 'good_afternoon'.tr();
    return 'good_evening'.tr();
  }

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
              Text(
                _greetingText(),
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

class _TrendingCategoriesSection extends ConsumerWidget {
  const _TrendingCategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(categoriesStreamProvider);
    final cats = asyncCats.value ?? const <CategoryModel>[];

    if (asyncCats.isLoading && cats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'trending_categories'.tr(),
              icon: Icons.local_fire_department_rounded,
            ),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, __) => const SizedBox(
                  width: 150,
                  child: Skeleton(radius: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (cats.isEmpty) return const SizedBox.shrink();

    final featured = cats.take(8).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'trending_categories'.tr(),
            icon: Icons.local_fire_department_rounded,
          ),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => FadeInRight(
                from: 16,
                duration: Duration(milliseconds: 280 + i * 50),
                child: AnimatedCategoryCard(
                  category: featured[i],
                  variant: AnimatedCategoryCardVariant.trendingHero,
                  heroPrefix: 'trending-',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── All categories grid ─────────────────────────────────────────────────

class _AllCategoriesSection extends ConsumerWidget {
  const _AllCategoriesSection();

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
          _SectionTitle(
            title: 'shop_by_category'.tr(),
            icon: Icons.grid_view_rounded,
          ),
          grid(
            count: cols * 3,
            builder: (_, __) => const Skeleton(radius: 14),
          ),
        ],
      );
    }
    if (cats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'shop_by_category'.tr(),
          icon: Icons.grid_view_rounded,
        ),
        grid(
          count: cats.length,
          builder: (context, i) => FadeInUp(
            from: 12,
            duration: Duration(milliseconds: 240 + (i % 12) * 30),
            child: AnimatedCategoryCard(category: cats[i]),
          ),
        ),
      ],
    );
  }
}

// ─── Section title ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppGradients.brand(),
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppShadow.dim,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppSurface.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
