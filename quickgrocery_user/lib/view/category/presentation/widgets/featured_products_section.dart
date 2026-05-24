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
    final products = (async.value ?? const <ProductModel>[])
        .where((p) => p.isAvailable)
        .take(maxItems)
        .toList();

    final header = SectionHeader(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actionLabel: onSeeAll != null ? 'See all' : null,
      onAction: onSeeAll,
    );

    if (async.isLoading && products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Builder(
              builder: (context) => SkeletonRail(
                count: 4,
                height: Responsive.horizontalProductRailHeight(context),
              ),
            ),
          ],
        ),
      );
    }
    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Builder(
            builder: (context) {
              final h = Responsive.horizontalProductRailHeight(context);
              return HorizontalProductRail(
                height: h,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => StaggeredFadeIn(
                  index: i,
                  child: HomeProductCard(product: products[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
