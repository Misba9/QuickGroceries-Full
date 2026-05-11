import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';
import 'package:quickgrocery/view/offers/presentation/utils/offer_navigation.dart';

/// Blinkit-style full-width promo card with muted looping video, gradient,
/// titles, optional countdown + discount chip, and CTA.
class OfferPromoVideoCard extends ConsumerStatefulWidget {
  const OfferPromoVideoCard({
    super.key,
    required this.offer,
    this.trackViewOnInit = true,
    this.borderRadius = 20,
  });

  final OfferBannerModel offer;
  final bool trackViewOnInit;
  final double borderRadius;

  @override
  ConsumerState<OfferPromoVideoCard> createState() =>
      _OfferPromoVideoCardState();
}

class _OfferPromoVideoCardState extends ConsumerState<OfferPromoVideoCard> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _fadeMedia = false;

  double get _height =>
      (widget.offer.bannerHeightPx ?? 200).clamp(180.0, 220.0);

  @override
  void initState() {
    super.initState();
    if (widget.trackViewOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(offerBannerRepositoryProvider).trackView(widget.offer);
      });
    }
    _bootVideo();
  }

  @override
  void didUpdateWidget(covariant OfferPromoVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offer.id != widget.offer.id ||
        oldWidget.offer.videoUrl != widget.offer.videoUrl) {
      _disposeVideo();
      _bootVideo();
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _fadeMedia = false;
  }

  Future<void> _bootVideo() async {
    final uri = Uri.tryParse(widget.offer.videoUrl.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _fadeMedia = true);
      return;
    }
    final c = VideoPlayerController.networkUrl(uri);
    try {
      await c.initialize();
      await c.setLooping(widget.offer.loop);
      await c.setVolume(widget.offer.muted ? 0 : 1);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
      if (widget.offer.autoplay) await c.play();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) setState(() => _fadeMedia = true);
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _fadeMedia = true);
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  String _countdownLabel() {
    final rem = widget.offer.timeRemaining;
    if (rem == null || rem == Duration.zero) return '';
    final h = rem.inHours.toString().padLeft(2, '0');
    final m = (rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final visible = info.visibleFraction > 0.12;
    if (visible) {
      if (widget.offer.autoplay && !c.value.isPlaying) c.play();
    } else {
      c.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    return VisibilityDetector(
      key: Key('promo_${widget.offer.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppSurface.subtle),
            AnimatedOpacity(
              opacity: _fadeMedia ? 1 : 0,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_ready && _controller != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  else if (widget.offer.thumbnailUrl.isNotEmpty)
                    CachedImage(
                      url: widget.offer.thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  else if (widget.offer.imageFallbackUrl.isNotEmpty)
                    CachedImage(
                      url: widget.offer.imageFallbackUrl,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.38),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            if (widget.offer.lottieUrl.trim().isNotEmpty)
              IgnorePointer(
                child: Lottie.network(
                  widget.offer.lottieUrl,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            if (widget.offer.discountBadgeLabel.trim().isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppSurface.danger,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppShadow.dim,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      widget.offer.discountBadgeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (_countdownLabel().isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _countdownLabel(),
                            style: GoogleFonts.poppins(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.offer.title.trim().isNotEmpty)
                    Text(
                      widget.offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  if (widget.offer.subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.offer.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.95),
                      foregroundColor: AppColor.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () =>
                        navigateFromOffer(context, ref, widget.offer),
                    child: Text(widget.offer.ctaText.trim().isEmpty
                        ? 'Shop now'
                        : widget.offer.ctaText),
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
