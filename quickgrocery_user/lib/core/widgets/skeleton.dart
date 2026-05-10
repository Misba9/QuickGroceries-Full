import 'package:flutter/material.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:shimmer/shimmer.dart';

import '../design/app_tokens.dart';

/// Lightweight skeleton primitive used to compose loading states.
///
/// Usage:
///   `Skeleton(width: 120, height: 14)`
///   `Skeleton.box(width: 80, height: 80, radius: 12)`
///   `Skeleton.circle(size: 36)`
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = 6,
  });

  factory Skeleton.box({
    Key? key,
    double? width,
    double? height,
    double radius = 12,
  }) =>
      Skeleton(key: key, width: width, height: height, radius: radius);

  factory Skeleton.circle({Key? key, required double size}) =>
      Skeleton(key: key, width: size, height: size, radius: size / 2);

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1100),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton row of horizontal product placeholders.
class SkeletonRail extends StatelessWidget {
  const SkeletonRail({super.key, this.count = 4, this.height = 220, this.itemWidth = 150});

  final int count;
  final double height;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: kHorizontalProductRailPhysics,
        padding: EdgeInsets.zero,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: itemWidth,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.all(AppRadii.md),
            border: Border.all(color: AppSurface.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Skeleton.box(
                  width: double.infinity,
                  radius: 12,
                ),
              ),
              const SizedBox(height: 10),
              const Skeleton(width: 60, height: 10),
              const SizedBox(height: 6),
              const Skeleton(height: 10),
              const SizedBox(height: 4),
              const Skeleton(width: 80, height: 10),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Skeleton(width: 40, height: 14),
                  Spacer(),
                  Skeleton(width: 40, height: 22, radius: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton grid for explore-style sections.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 6, this.crossAxisCount = 2});

  final int count;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.all(AppRadii.md),
          border: Border.all(color: AppSurface.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Expanded(child: Skeleton(radius: 12)),
            const SizedBox(height: 10),
            const Skeleton(width: 50, height: 9),
            const SizedBox(height: 6),
            const Skeleton(height: 10),
            const SizedBox(height: 4),
            const Skeleton(width: 80, height: 10),
            const SizedBox(height: 8),
            const Skeleton(width: 60, height: 14),
          ],
        ),
      ),
    );
  }
}
