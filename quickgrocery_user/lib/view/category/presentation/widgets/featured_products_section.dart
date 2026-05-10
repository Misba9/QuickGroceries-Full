import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/core/widgets/staggered_fade_in.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';

/// Reusable horizontal product rail used by the Categories discovery
/// page (Featured / Trending / Best sellers / Seasonal picks).
///
/// Renders a [SectionHeader]-style title row, a 250-tall horizontal
/// rail of [HomeProductCard]s with staggered fade-ins, and shimmer
/// placeholders while loading.
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

  /// Any provider that exposes a list of [ProductModel]s. Designed to
  /// accept the existing `trendingProductsStreamProvider`,
  /// `featuredProductsStreamProvider`, etc.
  final ProviderListenable<AsyncValue<List<ProductModel>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    final products = (async.value ?? const <ProductModel>[])
        .where((p) => p.isAvailable)
        .take(maxItems)
        .toList();

    if (async.isLoading && products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(title: title, subtitle: subtitle, icon: icon),
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
          _Header(
            title: title,
            subtitle: subtitle,
            icon: icon,
            onSeeAll: onSeeAll,
          ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.subtitle,
    this.icon,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: AppGradients.brand(),
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppShadow.dim,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppSurface.text,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppSurface.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
