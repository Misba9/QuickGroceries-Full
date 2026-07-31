import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/loading/widgets/home_section_shimmer.dart';
import 'package:quickgrocery/core/theme/themed_image_frame.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_branded_placeholder.dart';

/// Product image with shimmer placeholder, branded fallback, and smart [BoxFit].
class ProductDisplayImage extends StatelessWidget {
  const ProductDisplayImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.heroTag,
    this.memCacheWidth,
    this.fit,
  });

  final String url;
  final double width;
  final double height;
  final String? heroTag;
  final int? memCacheWidth;

  /// When null, uses [BoxFit.cover] for hero-sized areas (fills 60–70% band).
  final BoxFit? fit;

  /// Aspect-based fit when dimensions are known (e.g. after decode).
  static BoxFit fitForAspectRatio(double aspect) {
    if (aspect <= 0) return BoxFit.cover;
    if (aspect >= 0.88 && aspect <= 1.12) return BoxFit.cover;
    if (aspect > 1.4) return BoxFit.fitWidth;
    if (aspect < 0.7) return BoxFit.fitHeight;
    return BoxFit.cover;
  }

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return ProductBrandedPlaceholder(width: width, height: height);
    }

    final effectiveFit = fit ?? BoxFit.cover;
    final surface = AppSurface.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = memCacheWidth ??
        (width * dpr).round().clamp(120, 1200);
    final quality = heroTag != null || width >= 280
        ? FilterQuality.medium
        : FilterQuality.low;

    Widget image = CachedNetworkImage(
      imageUrl: url.trim(),
      width: width,
      height: height,
      fit: effectiveFit,
      alignment: Alignment.center,
      memCacheWidth: cacheW,
      filterQuality: quality,
      fadeInDuration: LoadingConstants.imageFadeIn,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (_, __) => SizedBox(
        width: width,
        height: height,
        child: AppShimmer(
          child: ColoredBox(
            color: context.appPalette.shimmerBase,
            child: const SizedBox.expand(),
          ),
        ),
      ),
      errorWidget: (_, __, ___) =>
          ProductBrandedPlaceholder(width: width, height: height),
    );

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return RepaintBoundary(
      child: ThemedNetworkImageFrame(
        borderRadius: BorderRadius.zero,
        child: ColoredBox(
          color: surface.subtle,
          child: SizedBox(width: width, height: height, child: image),
        ),
      ),
    );
  }
}
