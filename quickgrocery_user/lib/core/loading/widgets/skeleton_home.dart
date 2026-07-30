import 'package:flutter/material.dart';

import 'package:quickgrocery/core/loading/widgets/animated_category_loader.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_banner.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_product_card.dart';
import 'package:quickgrocery/core/loading/widgets/shimmer_widgets.dart';

/// Composite home-page skeleton (banner + categories + product rails).
class SkeletonHome extends StatelessWidget {
  const SkeletonHome({super.key, this.showCategoryHero = true});

  final bool showCategoryHero;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (showCategoryHero) ...[
          const CategoryLoaderBanner(),
          const SizedBox(height: 14),
        ],
        const ShimmerBox(height: 118, radius: 20),
        const SizedBox(height: 12),
        const ShimmerBox(height: 48, radius: 24),
        const SizedBox(height: 16),
        const SkeletonCategory(count: 8),
        const SizedBox(height: 18),
        const SkeletonBanner(height: 168),
        const SizedBox(height: 20),
        const ShimmerBox(height: 18, width: 140, radius: 6),
        const SizedBox(height: 12),
        const SkeletonProductRail(count: 4),
        const SizedBox(height: 20),
        const ShimmerBox(height: 18, width: 160, radius: 6),
        const SizedBox(height: 12),
        const SkeletonVendor(count: 2),
        const SizedBox(height: 20),
        const ShimmerBox(height: 18, width: 120, radius: 6),
        const SizedBox(height: 12),
        const SkeletonProductGrid(count: 4, childAspectRatio: 0.68),
      ],
    );
  }
}
