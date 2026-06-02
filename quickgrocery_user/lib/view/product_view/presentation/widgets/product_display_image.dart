import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:quickgrocery/view/product_view/presentation/widgets/product_branded_placeholder.dart';

/// Product image with shimmer, branded fallback, and smart [BoxFit] defaults.
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
    if (url.isEmpty) {
      return ProductBrandedPlaceholder(width: width, height: height);
    }

    final effectiveFit = fit ?? BoxFit.cover;

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: effectiveFit,
      alignment: Alignment.center,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 280),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => _ShimmerBox(width: width, height: height),
      errorWidget: (_, __, ___) =>
          ProductBrandedPlaceholder(width: width, height: height),
    );

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(width: width, height: height, color: Colors.grey.shade200),
    );
  }
}
