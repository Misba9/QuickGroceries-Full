import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/navigation/product_navigation.dart';
import 'package:quickgrocery/models/promo_model.dart';
import 'package:quickgrocery/view/category/presentation/providers/categories_discovery_providers.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';

/// Promo video / GIF / Lottie / image rail for the Categories discovery
/// page. Streams admin-controlled `promos/` documents and renders each
/// using the optimal player:
///
///   * `mediaType: 'video'`  → muted, autoplay, looping [VideoPlayer]
///   * `mediaType: 'lottie'` → [Lottie.network] animation
///   * `mediaType: 'gif'` or url ending in `.gif` → cached image
///   * default → cached image
///
/// Tapping a promo routes via the stored `redirectType + redirectId`
/// (category / product / external URL).
class PromoVideoSection extends ConsumerWidget {
  const PromoVideoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activePromosStreamProvider);
    final promos = async.value ?? const <PromoModel>[];

    if (async.isLoading && promos.isEmpty) {
      return AppLoading.section;
    }
    if (promos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: promos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => AnimatedOfferBanner(promo: promos[i]),
      ),
    );
  }
}

class AnimatedOfferBanner extends StatelessWidget {
  const AnimatedOfferBanner({super.key, required this.promo});

  final PromoModel promo;

  Color _hex(String hex, Color fallback) {
    final raw = hex.replaceAll('#', '').trim();
    if (raw.length != 6 && raw.length != 8) return fallback;
    final v = int.tryParse(raw, radix: 16);
    if (v == null) return fallback;
    return raw.length == 6 ? Color(0xFF000000 | v) : Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);
    final start = _hex(promo.gradientStart, const Color(0xFF7B61FF));
    final end = _hex(promo.gradientEnd, const Color(0xFF4F8DFF));

    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: promo.hasRedirect ? () => _handleTap(context) : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [start, end],
              ),
              boxShadow: AppShadow.card,
            ),
            child: Stack(
              children: [
                Positioned.fill(child: _Media(promo: promo)),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'OFFER',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (promo.title.isNotEmpty)
                        Text(
                          promo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                            height: 1.05,
                          ),
                        ),
                      if (promo.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          promo.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.94),
                            height: 1.25,
                          ),
                        ),
                      ],
                      if (promo.ctaLabel.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            promo.ctaLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    HapticFeedback.selectionClick();
    switch (ProductNavigation.normalizeRedirectType(promo.redirectType)) {
      case 'category':
        final categoryId = promo.redirectId.trim();
        if (categoryId.isEmpty) {
          AppSnackBar.error('Category unavailable', context: context);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryScreen(category: categoryId),
          ),
        );
        break;

      case 'product':
        await ProductNavigation.openProductById(context, promo.redirectId);
        break;

      case 'url':
        final uri = Uri.tryParse(promo.redirectId.trim());
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
      default:
        break;
    }
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.promo});
  final PromoModel promo;

  @override
  Widget build(BuildContext context) {
    if (promo.isVideo) return PromoVideoWidget(url: promo.mediaUrl);
    if (promo.isLottie) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Lottie.network(
          promo.mediaUrl,
          fit: BoxFit.contain,
        ),
      );
    }
    if (promo.mediaUrl.isEmpty) return const SizedBox.shrink();
    return CachedNetworkImage(
      imageUrl: promo.mediaUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// Standalone video player used by [AnimatedOfferBanner] (also exported for
/// admins / hosts that want to drop a single muted-loop video anywhere).
class PromoVideoWidget extends StatefulWidget {
  const PromoVideoWidget({super.key, required this.url});

  final String url;

  @override
  State<PromoVideoWidget> createState() => _PromoVideoWidgetState();
}

class _PromoVideoWidgetState extends State<PromoVideoWidget> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      c.setLooping(true);
      c.setVolume(0);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
    } catch (_) {
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
