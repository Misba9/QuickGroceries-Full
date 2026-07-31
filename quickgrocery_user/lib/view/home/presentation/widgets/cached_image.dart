import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/loading/widgets/home_section_shimmer.dart';

/// Lightweight wrapper around [CachedNetworkImage] with sensible defaults
/// (reserved size, soft shimmer placeholder, fade-in) used on the homepage.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (url.isEmpty) {
      image = _Fallback(width: width, height: height);
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: LoadingConstants.imageFadeIn,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        placeholder: (context, _) =>
            _ShimmerPlaceholder(width: width, height: height),
        errorWidget: (context, _, __) =>
            _Fallback(width: width, height: height),
      );
    }
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AppShimmer(
        child: ShimmerBox(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: 0,
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
    return Container(
      width: width,
      height: height,
      color: surface.subtle,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: surface.textMuted,
        size: 28,
      ),
    );
  }
}
