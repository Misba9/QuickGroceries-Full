import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_helpers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Full-width promo strip for admin-uploaded MP4 banners (`banners/`).
///
/// Use [segmentCount] / [segmentIndex] to split videos across two home rows
/// (even / odd ordering) without extra admin fields.
///
/// Set [snapPaging] for Categories-style **page snapping** between promos.
class HomeBannerVideoRail extends ConsumerStatefulWidget {
  const HomeBannerVideoRail({
    super.key,
    this.title = 'Spotlight',
    this.segmentCount = 1,
    this.segmentIndex = 0,
    this.showHeader = true,
    this.snapPaging = false,
    this.pageFraction = 0.88,
  });

  final String title;
  final int segmentCount;
  final int segmentIndex;

  /// When false, renders only the horizontal video strip (embedded headers).
  final bool showHeader;

  /// Snap between videos with [PageView] (smooth quick-commerce style).
  final bool snapPaging;

  /// Viewport fraction when [snapPaging] is true.
  final double pageFraction;

  @override
  ConsumerState<HomeBannerVideoRail> createState() =>
      _HomeBannerVideoRailState();
}

class _HomeBannerVideoRailState extends ConsumerState<HomeBannerVideoRail> {
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    if (widget.snapPaging) {
      _pageController = PageController(viewportFraction: widget.pageFraction);
    }
  }

  @override
  void didUpdateWidget(covariant HomeBannerVideoRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapPaging != oldWidget.snapPaging ||
        widget.pageFraction != oldWidget.pageFraction) {
      _pageController?.dispose();
      _pageController = widget.snapPaging
          ? PageController(viewportFraction: widget.pageFraction)
          : null;
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  List<BannerModel> _segment(List<BannerModel> all) {
    if (widget.segmentCount <= 1 || all.isEmpty) return all;
    final idx = widget.segmentIndex % widget.segmentCount;
    final out = <BannerModel>[];
    for (var i = 0; i < all.length; i++) {
      if (i % widget.segmentCount == idx) out.add(all[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bannersStreamProvider);

    return async.when(
      loading: () =>
          HomeShimmer.videoRail(showHeader: widget.showHeader),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        final all = promoVideoBanners(banners);
        final videos = _segment(all);
        if (videos.isEmpty) return const SizedBox.shrink();

        final header = widget.showHeader
            ? SectionHeader(
                title: widget.title,
                icon: Icons.play_circle_filled_rounded,
                compact: true,
              )
            : null;

        Widget rail;
        if (widget.snapPaging && _pageController != null) {
          final ctrl = _pageController!;
          final w = MediaQuery.sizeOf(context).width * widget.pageFraction;
          if (videos.length == 1) {
            rail = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _PromoVideoCard(banner: videos.first, cardWidth: w),
            );
          } else {
            rail = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 218,
                  child: PageView.builder(
                    controller: ctrl,
                    physics: const BouncingScrollPhysics(),
                    padEnds: true,
                    itemCount: videos.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _PromoVideoCard(
                        banner: videos[i],
                        cardWidth: w - 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _VideoPageDots(
                  controller: ctrl,
                  count: videos.length,
                ),
              ],
            );
          }
        } else {
          rail = SizedBox(
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _PromoVideoCard(banner: videos[i]),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) header,
            rail,
          ],
        );
      },
    );
  }
}

class _VideoPageDots extends StatelessWidget {
  const _VideoPageDots({
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

class _PromoVideoCard extends StatefulWidget {
  const _PromoVideoCard({
    required this.banner,
    this.cardWidth,
  });

  final BannerModel banner;

  /// Fixed width for snap/carousel layouts; default uses ~82% screen clamp.
  final double? cardWidth;

  @override
  State<_PromoVideoCard> createState() => _PromoVideoCardState();
}

class _PromoVideoCardState extends State<_PromoVideoCard> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uri = Uri.tryParse(widget.banner.video.trim());
    if (uri == null || !uri.hasScheme) return;
    final c = VideoPlayerController.networkUrl(uri);
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
      await c.play();
    } catch (_) {
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePause() async {
    final c = _controller;
    if (c == null || !_ready) return;
    HapticFeedback.selectionClick();
    if (_paused) {
      await c.play();
    } else {
      await c.pause();
    }
    setState(() => _paused = !_paused);
  }

  Future<void> _handleTap(BuildContext context) async {
    final b = widget.banner;
    if (!b.hasRedirect) return;
    switch (b.redirectType) {
      case 'category':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryScreen(category: b.redirectId),
          ),
        );
        break;
      case 'product':
        final cartService =
            legacy.Provider.of<CategoryService>(context, listen: false);
        final ProductModel? product = cartService.allProducts
            .where((p) => p.id == b.redirectId)
            .cast<ProductModel?>()
            .firstWhere((p) => p != null, orElse: () => null);
        if (product != null && context.mounted) {
          Navigator.push(context, AppPageRoutes.product(product));
        }
        break;
      case 'url':
        final uri = Uri.tryParse(b.redirectId);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
      default:
        break;
    }
  }

  String _ctaLabel() {
    final b = widget.banner;
    if (b.ctaLabel.trim().isNotEmpty) return b.ctaLabel.trim();
    if (b.hasRedirect) return context.l10n.shop_now_cta;
    return context.l10n.explore_cta;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final width = widget.cardWidth ??
        (screenW * 0.82).clamp(260.0, 420.0);
    final radius = BorderRadius.circular(24);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadow.raised,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppSurface.subtle),
                if (_ready && _controller != null)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                else if (widget.banner.image.isNotEmpty)
                  CachedImage(
                    url: widget.banner.image,
                    fit: BoxFit.cover,
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.28),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _togglePause,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          _paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 22,
                          color: AppSurface.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.95),
                      foregroundColor: AppColor.primary,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: widget.banner.hasRedirect
                        ? () => _handleTap(context)
                        : () {
                            HapticFeedback.lightImpact();
                            AppSnackBar.info(
                              context.l10n.promo_more_soon,
                              context: context,
                            );
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_ctaLabel()),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: widget.banner.hasRedirect
                              ? AppColor.primary
                              : AppSurface.textMuted,
                        ),
                      ],
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
