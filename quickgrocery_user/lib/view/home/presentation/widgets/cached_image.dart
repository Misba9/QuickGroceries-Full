import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/loading/widgets/home_section_shimmer.dart';

/// App-wide network image: [CachedNetworkImage] + shimmer + soft fallback.
///
/// - Never empty / never black while loading
/// - Soft fade-in when decoded
/// - Bounded decode via [memCacheWidth] / [memCacheHeight]
/// - [RepaintBoundary] to avoid parent rebuilds repainting the bitmap
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeIn = true,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// When false (e.g. splash category loop), skip fade to keep FPS smooth.
  final bool fadeIn;

  /// Default decode width for list thumbs when caller omits [memCacheWidth].
  static const int defaultThumbCacheWidth = 400;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    final dpr = MediaQuery.devicePixelRatioOf(context);

    int? cacheW = memCacheWidth;
    int? cacheH = memCacheHeight;
    if (cacheW == null && width != null && width!.isFinite && width! > 0) {
      cacheW = (width! * dpr).round().clamp(48, 1200);
    }
    if (cacheH == null && height != null && height!.isFinite && height! > 0) {
      cacheH = (height! * dpr).round().clamp(48, 1200);
    }
    // List/grid cells without explicit size still bound decode cost.
    cacheW ??= defaultThumbCacheWidth;

    Widget image;
    if (trimmed.isEmpty) {
      image = _Fallback(width: width, height: height);
    } else {
      image = CachedNetworkImage(
        imageUrl: trimmed,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        filterQuality: FilterQuality.low,
        fadeInDuration:
            fadeIn ? LoadingConstants.imageFadeIn : Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        placeholder: (context, _) =>
            _ShimmerPlaceholder(width: width, height: height),
        errorWidget: (context, _, __) =>
            _Fallback(width: width, height: height),
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    // Isolate bitmap paints from parent setState storms.
    return RepaintBoundary(child: image);
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    // Opaque shimmerBase fill — never black / never empty hole.
    return SizedBox(
      width: width,
      height: height,
      child: AppShimmer(
        child: ColoredBox(
          color: palette.shimmerBase,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return ColoredBox(
      color: surface.subtle,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: surface.textMuted,
            size: (height != null && height! < 48) ? 16 : 28,
          ),
        ),
      ),
    );
  }
}
