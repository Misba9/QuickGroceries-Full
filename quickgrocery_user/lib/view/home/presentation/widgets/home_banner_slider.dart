import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';

const double _kBannerAspect = 16 / 7;
const double _kViewportFraction = 0.926; // ~slidesPerView 1.08
const double _kSlideGap = 12;

/// Premium full-bleed home banner carousel (Blinkit / Zepto style).
///
/// * **16:7** aspect per slide — immersive, not oversized.
/// * **`viewportFraction` ~0.926** — ~1.08 slides visible with side peek.
/// * **`BoxFit.cover`** — no gray letterboxing from `object-contain`.
/// * **24 px radius**, soft shadow, worm indicators, pause-on-touch autoplay.
class HomeBannerSlider extends StatefulWidget {
  const HomeBannerSlider({super.key, required this.banners});

  final List<BannerModel> banners;

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  int _index = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    final loop = banners.length > 1;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final slideW = viewportW * _kViewportFraction;
        final carouselH = slideW / _kBannerAspect;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: carouselH,
              child: CarouselSlider.builder(
                carouselController: _controller,
                itemCount: banners.length,
                itemBuilder: (context, i, _) => _BannerSlide(
                  banner: banners[i],
                  cacheWidth: (slideW * dpr).round(),
                ),
                options: CarouselOptions(
                  height: carouselH,
                  viewportFraction: _kViewportFraction,
                  padEnds: true,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.06,
                  autoPlay: loop,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: AppMotion.medium,
                  autoPlayCurve: AppMotion.emphasized,
                  pauseAutoPlayOnTouch: true,
                  pauseAutoPlayOnManualNavigate: true,
                  enableInfiniteScroll: loop,
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (i, _) => setState(() => _index = i),
                ),
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 10),
              _PageIndicator(
                count: banners.length,
                activeIndex: _index,
                onTap: (i) => _controller.animateToPage(
                  i,
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Slide ───────────────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({
    required this.banner,
    required this.cacheWidth,
  });

  final BannerModel banner;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.banner);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kSlideGap / 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadow.card,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AspectRatio(
            aspectRatio: _kBannerAspect,
            child: Material(
              color: AppSurface.subtle,
              child: InkWell(
                onTap: banner.hasRedirect ? () => _handleTap(context) : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (banner.isVideo && banner.effectiveVideoUrl.isNotEmpty)
                      _BannerVideoPlayer(url: banner.effectiveVideoUrl)
                    else
                      CachedImage(
                        url: banner.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        memCacheWidth: cacheWidth,
                        memCacheHeight: (cacheWidth / _kBannerAspect).round(),
                      ),
                    const _GradientScrim(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    switch (banner.redirectType) {
      case 'offers_page':
        legacy.Provider.of<HomeProvider>(context, listen: false)
            .onSelectedChange(2);
        break;

      case 'category':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryScreen(category: banner.redirectId),
          ),
        );
        break;

      case 'product':
        final cartService = legacy.Provider.of<CategoryService>(
          context,
          listen: false,
        );
        final ProductModel? product = cartService.allProducts
            .where((p) => p.id == banner.redirectId)
            .cast<ProductModel?>()
            .firstWhere((p) => p != null, orElse: () => null);
        if (product != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductViewScreen(product: product),
            ),
          );
        }
        break;

      case 'url':
        final uri = Uri.tryParse(banner.redirectId);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;

      default:
        break;
    }
  }
}

class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.05),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.14),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}

// ─── Indicator ───────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.emphasized,
              height: 6,
              width: active ? 22 : 6,
              decoration: BoxDecoration(
                color: active ? AppColor.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Video slide ─────────────────────────────────────────────────────────

class _BannerVideoPlayer extends StatefulWidget {
  const _BannerVideoPlayer({required this.url});
  final String url;

  @override
  State<_BannerVideoPlayer> createState() => _BannerVideoPlayerState();
}

class _BannerVideoPlayerState extends State<_BannerVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (_) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const _BannerMediaSkeleton();
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}

/// Shimmer placeholder while banner media loads.
class _BannerMediaSkeleton extends StatelessWidget {
  const _BannerMediaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppSurface.subtle,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
