import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/widgets/shimmer_widgets.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';

/// Product card placeholder matching real product tile proportions.
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({
    super.key,
    this.width = 150,
    this.height = 220,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: AppRadii.all(AppRadii.md),
        border: Border.all(color: surface.border),
      ),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surface.shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const SkeletonBone(width: 52, height: 9, radius: 4),
            const SizedBox(height: 6),
            const SkeletonBone(height: 10),
            const SizedBox(height: 4),
            const SkeletonBone(width: 80, height: 10),
            const SizedBox(height: 8),
            const Row(
              children: [
                SkeletonBone(width: 40, height: 14),
                Spacer(),
                SkeletonBone(width: 40, height: 22, radius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonProductRail extends StatelessWidget {
  const SkeletonProductRail({
    super.key,
    this.count = 4,
    this.height = 220,
    this.itemWidth = 150,
  });

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
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => SkeletonProductCard(
          width: itemWidth,
          height: height,
        ),
      ),
    );
  }
}

class SkeletonProductGrid extends StatelessWidget {
  const SkeletonProductGrid({
    super.key,
    this.count = 6,
    this.crossAxisCount = 2,
    this.padding = EdgeInsets.zero,
    this.childAspectRatio = 0.62,
  });

  final int count;
  final int crossAxisCount;
  final EdgeInsetsGeometry padding;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: surface.card,
          borderRadius: AppRadii.all(AppRadii.md),
          border: Border.all(color: surface.border),
        ),
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surface.shimmerBase,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SkeletonBone(width: 50, height: 9, radius: 4),
              const SizedBox(height: 6),
              const SkeletonBone(height: 10),
              const SizedBox(height: 4),
              const SkeletonBone(width: 80, height: 10),
              const SizedBox(height: 8),
              const SkeletonBone(width: 60, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
