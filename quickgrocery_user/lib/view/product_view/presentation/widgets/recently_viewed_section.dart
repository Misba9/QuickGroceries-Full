import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/recently_viewed_provider.dart';

/// Recently viewed products rail.
///
/// Reads ids from [SharedPreferences], hydrates against `products` and
/// silently hides itself if the user has no qualifying history.
class RecentlyViewedSection extends ConsumerWidget {
  const RecentlyViewedSection({super.key, required this.currentProductId});

  final String currentProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      recentlyViewedProductsProvider(currentProductId),
    );

    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Recently viewed'),
            HomeShimmer.horizontalProducts(
              height: Responsive.horizontalProductRailHeight(context),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Recently viewed'),
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
