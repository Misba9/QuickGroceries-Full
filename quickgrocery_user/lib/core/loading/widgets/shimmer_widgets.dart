import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:shimmer/shimmer.dart';

/// Theme-aware shimmer primitive — use everywhere instead of grey hardcodes.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.margin,
  });

  factory ShimmerBox.circle({Key? key, required double size}) =>
      ShimmerBox(key: key, width: size, height: size, radius: size / 2);

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final surface = AppSurface.of(context);
    final child = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: surface.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (reduceMotion) return child;
    return Shimmer.fromColors(
      baseColor: surface.shimmerBase,
      highlightColor: surface.shimmerHighlight,
      period: const Duration(milliseconds: 1100),
      child: child,
    );
  }
}

/// Shared shimmer wrapper for composed skeletons.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;
    final surface = AppSurface.of(context);
    return Shimmer.fromColors(
      baseColor: surface.shimmerBase,
      highlightColor: surface.shimmerHighlight,
      period: const Duration(milliseconds: 1100),
      child: child,
    );
  }
}

/// Bone box used inside [AppShimmer] (no nested shimmer).
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppSurface.of(context).shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
