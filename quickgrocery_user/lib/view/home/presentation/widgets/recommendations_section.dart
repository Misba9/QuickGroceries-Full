import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/core/widgets/staggered_fade_in.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/recently_viewed_provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// "Picked for you" rail. Personalizes via:
///   1. Recently viewed product ids (Step 2).
///   2. Recently ordered category names (Step 4).
///   3. Falls back to featured products if both are empty.
///
/// All inputs are autoDispose Riverpod providers, so signing out cleans
/// up the underlying Firestore listeners automatically.
class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({
    super.key,
    this.maxItems = 12,
    this.sectionTitle,
  });

  final int maxItems;

  /// Defaults to [picked_for_you] translation.
  final String? sectionTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyViewed = ref.watch(recentlyViewedProductsProvider(''));
    final ordersAsync = ref.watch(userOrdersStreamProvider);
    final featured = ref.watch(featuredProductsStreamProvider);
    final trending = ref.watch(trendingProductsStreamProvider);

    final viewed = recentlyViewed.asData?.value ?? const <ProductModel>[];
    final featuredList = featured.asData?.value ?? const <ProductModel>[];
    final trendingList = trending.asData?.value ?? const <ProductModel>[];

    final orderedCategories = <String>{};
    for (final order in (ordersAsync.asData?.value ?? const [])) {
      for (final p in order.legacy.products) {
        if (p.category.trim().isNotEmpty) {
          orderedCategories.add(p.category.trim().toLowerCase());
        }
      }
    }

    final seen = <String>{};
    final out = <ProductModel>[];

    void add(Iterable<ProductModel> list) {
      for (final p in list) {
        if (out.length >= maxItems) return;
        if (!p.isAvailable) continue;
        if (seen.add(p.id)) out.add(p);
      }
    }

    add(viewed);

    if (orderedCategories.isNotEmpty) {
      bool match(ProductModel p) =>
          orderedCategories.contains(p.category.trim().toLowerCase()) ||
          orderedCategories.contains(p.subcategory.trim().toLowerCase());
      add(featuredList.where(match));
      add(trendingList.where(match));
    }

    add(featuredList);
    add(trendingList);

    final title = sectionTitle ?? context.l10n.picked_for_you;

    if (out.isEmpty && (featured.isLoading || trending.isLoading)) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title),
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
    if (out.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          Builder(
            builder: (context) {
              final h = Responsive.horizontalProductRailHeight(context);
              return HorizontalProductRail(
                height: h,
                itemCount: out.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => StaggeredFadeIn(
                  index: i,
                  child: HomeProductCard(product: out[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
