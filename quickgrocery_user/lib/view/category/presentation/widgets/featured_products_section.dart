import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/core/widgets/staggered_fade_in.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';

/// Reusable horizontal product rail used by the Categories discovery
/// page (Featured / Trending / Best sellers / Seasonal picks).
class FeaturedProductsSection extends ConsumerWidget {
  const FeaturedProductsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.provider,
    this.icon,
    this.maxItems = 12,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final int maxItems;
  final VoidCallback? onSeeAll;

  final ProviderListenable<AsyncValue<List<ProductModel>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    final header = SectionHeader(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actionLabel: onSeeAll != null ? 'See all' : null,
      onAction: onSeeAll,
    );

    return async.when(
      skipLoadingOnReload: false,
      loading: () => _buildSkeleton(context, header),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final products = list
            .where((p) => p.isAvailable)
            .take(maxItems)
            .toList();
        if (products.isEmpty) return const SizedBox.shrink();
        return _buildRail(context, header, products);
      },
    );
  }

  Widget _buildSkeleton(BuildContext context, Widget header) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SkeletonRail(
            count: 4,
            height: Responsive.horizontalProductRailHeight(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRail(
    BuildContext context,
    Widget header,
    List<ProductModel> products,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          HorizontalProductRail(
            height: Responsive.horizontalProductRailHeight(context),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => StaggeredFadeIn(
              index: i,
              child: HomeProductCard(product: products[i]),
            ),
          ),
        ],
      ),
    );
  }
}
