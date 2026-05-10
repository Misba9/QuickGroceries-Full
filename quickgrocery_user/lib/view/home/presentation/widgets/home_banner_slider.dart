import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';

/// Premium auto-sliding banner carousel — Zepto / Blinkit / Instamart style.
///
/// Design choices:
/// * **Aspect 16:7** so banners feel cinematic regardless of device width.
/// * **`enlargeCenterPage`** with a soft scale so neighbouring slides
///   *peek* in the gutter — modern grocery-app feel.
/// * **Soft shadow + 18 px radius** via design tokens; consistent with
///   the rest of the home surface.
/// * **Worm-style indicator**: active dot stretches into a pill while
///   the others remain compact, animated with `AppMotion.short`.
/// * **Pause on touch** so users can read or tap before the next slide.
/// * **Image + video**: video slides loop muted, fall back gracefully on
///   load failure.
/// * **Tap routing** maps `redirectType` → category / product / external URL.
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

    final responsive = Responsive.of(context);
    final width = MediaQuery.of(context).size.width - 2 * responsive.gutter();
    // Strict 16:7 — tall enough on phones so creative isn't over-cropped.
    final height = (width * 7 / 16).clamp(168.0, 280.0);
    final loop = banners.length > 1;

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: banners.length,
          itemBuilder: (context, i, _) => _BannerSlide(banner: banners[i]),
          options: CarouselOptions(
            height: height,
            viewportFraction: 1,
            enlargeCenterPage: false,
            enlargeFactor: 0,
            autoPlay: loop,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: AppMotion.medium,
            autoPlayCurve: AppMotion.emphasized,
            pauseAutoPlayOnTouch: true,
            pauseAutoPlayOnManualNavigate: true,
            enableInfiniteScroll: loop,
            onPageChanged: (i, _) => setState(() => _index = i),
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
  }
}

// ─── Slide ───────────────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});

  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadow.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: banner.hasRedirect ? () => _handleTap(context) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppSurface.subtle),
                if (banner.isVideo && banner.video.isNotEmpty)
                  _BannerVideoPlayer(url: banner.video)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: CachedImage(
                        url: banner.image,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                // Premium bottom scrim + slight top fade so artwork stays visible.
                const _GradientScrim(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    switch (banner.redirectType) {
      case 'category':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryScreen(category: banner.redirectId),
          ),
        );
        break;

      case 'product':
        // Resolve from the cart/category service's already-cached product
        // list so a banner tap doesn't trigger a fresh Firestore fetch.
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
              Colors.black.withValues(alpha: 0.04),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.12),
            ],
            stops: const [0, 0.45, 1],
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
      return Container(color: AppSurface.subtle);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
