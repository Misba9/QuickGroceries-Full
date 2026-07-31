import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_status_views.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/product_detail_providers.dart';

/// Horizontal rail of products in the same category. Hides itself
/// silently when no similar products are available so the page collapses
/// gracefully on niche items.
class SimilarProductsSection extends ConsumerWidget {
  const SimilarProductsSection({
    super.key,
    required this.category,
    required this.excludeId,
  });

  final String category;
  final String excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      similarProductsStreamProvider(
        SimilarProductsKey(category: category, excludeId: excludeId),
      ),
    );

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Similar products'),
            AppLoading.section,
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: HomeErrorView(
          message: 'Couldn\'t load similar products',
          onRetry: () => ref.invalidate(
            similarProductsStreamProvider(
              SimilarProductsKey(category: category, excludeId: excludeId),
            ),
          ),
        ),
      ),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Similar products'),
              HorizontalProductRail(
                height: Responsive.horizontalProductRailHeight(context),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) =>
                    HomeProductCard(product: products[i]),
              ),
            ],
          ),
        );
      },
    );
  }
}
