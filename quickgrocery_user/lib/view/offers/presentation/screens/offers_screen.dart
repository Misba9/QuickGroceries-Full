import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/cart/data/coupon_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/delivery/domain/delivery_pricing_policy.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/category/presentation/widgets/featured_products_section.dart';
import 'package:quickgrocery/view/coupons/coupon_screen.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/flash_sale_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/recommendations_section.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/offer_promo_video_card.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/offer_story_strip.dart';

/// Dedicated Offers hub — hero video carousel, stories, flash deals,
/// coupons, and curated product rails (Blinkit / Zepto style).
class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  int _heroIndex = 0;
  final CarouselSliderController _heroCtrl = CarouselSliderController();

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    ref.invalidate(offersPageBannersProvider);
    ref.invalidate(offersStoriesProvider);
    ref.invalidate(popupEligibleOffersProvider);
    ref.invalidate(promotionPopupSettingsProvider);
    ref.invalidate(trendingProductsStreamProvider);
    ref.invalidate(featuredProductsStreamProvider);
    ref.invalidate(couponsStreamProvider);
    ref.invalidate(bannersStreamProvider);
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  OfferBannerModel? _fallbackFromHomeBanners(List<BannerModel>? list) {
    if (list == null) return null;
    for (final b in list) {
      if (b.isScheduleOk && b.isImage && b.image.isNotEmpty) {
        return OfferBannerModel.fromAdminBanner(b);
      }
    }
    for (final b in list) {
      if (b.isScheduleOk && b.hasPromoMedia) {
        return OfferBannerModel.fromAdminBanner(b);
      }
    }
    return null;
  }

  List<OfferBannerModel> _storyOffers(
    AsyncValue<List<OfferBannerModel>> storiesAsync,
    AsyncValue<List<OfferBannerModel>> pageAsync,
  ) {
    final dedicated = storiesAsync.valueOrNull ?? const [];
    if (dedicated.isNotEmpty) return dedicated;
    final page = pageAsync.valueOrNull ?? const [];
    return page.take(10).toList();
  }

  List<OfferBannerModel> _endingSoon(List<OfferBannerModel> all) {
    return all
        .where((o) => o.endsAt != null && !o.isExpired && o.timeRemaining != null)
        .toList()
      ..sort((a, b) => (a.endsAt!).compareTo(b.endsAt!));
  }

  @override
  Widget build(BuildContext context) {
    final gutter = Responsive.of(context).gutter();
    final pageAsync = ref.watch(offersPageBannersProvider);
    final bannersRawAsync = ref.watch(bannersStreamProvider);
    final storiesAsync = ref.watch(offersStoriesProvider);
    final List<OfferBannerModel> primary =
        pageAsync.value ?? const <OfferBannerModel>[];
    final fallback =
        _fallbackFromHomeBanners(bannersRawAsync.valueOrNull);
    final List<OfferBannerModel> banners = primary.isNotEmpty
        ? primary
        : (fallback != null ? <OfferBannerModel>[fallback] : const []);
    final heroLoading =
        pageAsync.isLoading && primary.isEmpty && fallback == null;
    final storyOffers = _storyOffers(storiesAsync, pageAsync);
    final endingSoon = _endingSoon(banners);
    final couponsAsync = ref.watch(couponsStreamProvider);
    final pricing = ref.watch(pricingConfigProvider).value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        legacy.Provider.of<HomeProvider>(context, listen: false)
            .onSelectedChange(0);
      },
      child: Scaffold(
        backgroundColor: AppSurface.background,
        body: RefreshIndicator(
          color: AppColor.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: AppSurface.background,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Offers & deals',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppSurface.textPrimary,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: OfferStoryStrip(offers: storyOffers),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 8),
                  child: _OffersHeroCarousel(
                    banners: banners,
                    isLoading: heroLoading,
                    carouselController: _heroCtrl,
                    heroIndex: _heroIndex,
                    onPageChanged: (i) => setState(() => _heroIndex = i),
                  ),
                ),
              ),
              if (pricing != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppSurface.border),
                      ),
                      child: Text(
                        DeliveryPricingPolicy.offersLine(pricing),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppSurface.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: const FlashSaleSection(
                    cardMargin: EdgeInsets.only(top: 8),
                  ),
                ),
              ),
              if (endingSoon.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Ends soon'),
                        SizedBox(
                          height: 216,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: endingSoon.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) => SizedBox(
                              width: MediaQuery.sizeOf(context).width - gutter * 2 - 48,
                              child: OfferPromoVideoCard(
                                offer: endingSoon[i],
                                trackViewOnInit: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: FeaturedProductsSection(
                    title: 'Trending offers',
                    subtitle: 'Most-loved picks right now',
                    icon: Icons.local_fire_department_rounded,
                    provider: trendingProductsStreamProvider,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
                  child: _CouponStrip(asyncCoupons: couponsAsync),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: FeaturedProductsSection(
                    title: 'Buy 1 Get 1',
                    subtitle: 'Bundles & pairs',
                    icon: Icons.all_inclusive_rounded,
                    provider: specialCatProductsProvider('Buy 1 Get 1'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: FeaturedProductsSection(
                    title: 'Limited stock deals',
                    subtitle: 'Selling fast',
                    icon: Icons.inventory_2_outlined,
                    provider: specialCatProductsProvider('Epic price drop items'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: FeaturedProductsSection(
                    title: 'Festival offers',
                    subtitle: 'Seasonal savings',
                    icon: Icons.celebration_outlined,
                    provider: specialCatProductsProvider('Festival offers'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: RecommendationsSection(
                    sectionTitle: 'Recommended deals',
                  ),
                ),
              ),
              if (pageAsync.hasError && primary.isEmpty && fallback == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(gutter),
                      child: Text(
                        'Could not load offers. Pull to retry.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppSurface.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffersHeroCarousel extends StatelessWidget {
  const _OffersHeroCarousel({
    required this.banners,
    required this.isLoading,
    required this.carouselController,
    required this.heroIndex,
    required this.onPageChanged,
  });

  final List<OfferBannerModel> banners;
  final bool isLoading;
  final CarouselSliderController carouselController;
  final int heroIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (isLoading && banners.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColor.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (banners.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 200,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.primary.withValues(alpha: 0.12),
                Colors.white,
              ],
            ),
          ),
          child: Text(
            'No active promo in Offers yet. Add a video or image banner in '
            'Admin → Banner (enable “Show on Offers page”).',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppSurface.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final loop = banners.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarouselSlider.builder(
          carouselController: carouselController,
          itemCount: banners.length,
          itemBuilder: (context, i, _) {
            return OfferPromoVideoCard(
              offer: banners[i],
              trackViewOnInit: false,
              borderRadius: 24,
            );
          },
          options: CarouselOptions(
            viewportFraction: 1,
            enlargeCenterPage: false,
            height: (banners.first.bannerHeightPx ?? 200).clamp(180.0, 220.0),
            autoPlay: loop,
            autoPlayInterval: const Duration(seconds: 8),
            autoPlayAnimationDuration: AppMotion.medium,
            enableInfiniteScroll: loop,
            pauseAutoPlayOnTouch: true,
            pauseAutoPlayOnManualNavigate: true,
            onPageChanged: (i, _) => onPageChanged(i),
          ),
        ),
        if (loop) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < banners.length; i++)
                GestureDetector(
                  onTap: () => carouselController.animateToPage(
                    i,
                    duration: AppMotion.medium,
                    curve: AppMotion.emphasized,
                  ),
                  child: AnimatedContainer(
                    duration: AppMotion.short,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == heroIndex ? 22 : 6,
                    decoration: BoxDecoration(
                      color: i == heroIndex
                          ? AppColor.primary
                          : AppSurface.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CouponStrip extends StatelessWidget {
  const _CouponStrip({required this.asyncCoupons});

  final AsyncValue<List<CouponEntry>> asyncCoupons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Coupons for you',
          actionLabel: 'See all',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CouponScreen(),
              ),
            );
          },
        ),
        asyncCoupons.when(
          loading: () => const SizedBox(
            height: 52,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Text(
            'Coupons unavailable',
            style: GoogleFonts.poppins(color: AppSurface.textMuted, fontSize: 13),
          ),
          data: (coupons) {
            if (coupons.isEmpty) {
              return Text(
                'New coupons drop soon.',
                style: GoogleFonts.poppins(
                  color: AppSurface.textSecondary,
                  fontSize: 13,
                ),
              );
            }
            return SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = coupons[i];
                  final code = c.code;
                  final pct = c.discountPercent;
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    elevation: 0,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CouponScreen(),
                          ),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: AppSurface.border),
                          gradient: LinearGradient(
                            colors: [
                              AppColor.primary.withValues(alpha: 0.08),
                              Colors.white,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sell_rounded,
                                size: 18, color: AppColor.primary),
                            const SizedBox(width: 8),
                            Text(
                              '$code · $pct% off',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
