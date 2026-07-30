import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/widgets/shimmer_widgets.dart';

/// Full-bleed banner / carousel placeholder.
class SkeletonBanner extends StatelessWidget {
  const SkeletonBanner({
    super.key,
    this.height = 168,
    this.radius = AppRadii.banner,
  });

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(height: height, radius: radius);
  }
}

/// Horizontal category chip / tile rail.
class SkeletonCategory extends StatelessWidget {
  const SkeletonCategory({
    super.key,
    this.count = 8,
    this.height = 128,
  });

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SizedBox(
          width: 96,
          child: Column(
            children: [
              const Expanded(child: ShimmerBox(radius: 18)),
              const SizedBox(height: 8),
              const ShimmerBox(height: 10, width: 52, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vendor / store card placeholders.
class SkeletonVendor extends StatelessWidget {
  const SkeletonVendor({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Column(
      children: List.generate(count, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface.card,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: surface.border),
            ),
            child: const AppShimmer(
              child: Row(
                children: [
                  SkeletonBone(width: 64, height: 64, radius: 14),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(height: 14, width: 140),
                        SizedBox(height: 8),
                        SkeletonBone(height: 10, width: 100),
                        SizedBox(height: 8),
                        SkeletonBone(height: 10, width: 80),
                      ],
                    ),
                  ),
                  SkeletonBone(width: 48, height: 28, radius: 8),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
