import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:share_plus/share_plus.dart' show Share;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/core/product/product_quantity_label.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/delivery/domain/delivery_pricing_policy.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/product_detail_providers.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/recently_viewed_provider.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/cart_action_bar.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_detail_shimmer.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_image_carousel.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_review_widget.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_variant_widget.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/recently_viewed_section.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/similar_products_section.dart';

/// Modern, fully-dynamic product details screen.
///
/// The constructor signature (`{required ProductModel product}`) is
/// unchanged so every existing navigation site keeps working.
/// The bootstrap [product] is shown immediately (no flicker) while the
/// realtime Firestore document upgrades it under the hood.
class ProductViewScreen extends ConsumerStatefulWidget {
  const ProductViewScreen({super.key, required this.product});
  final ProductModel product;

  @override
  ConsumerState<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends ConsumerState<ProductViewScreen> {
  @override
  void initState() {
    super.initState();
    // Persist this product into recently-viewed history.
    Future.microtask(() {
      ref.read(recentlyViewedIdsProvider.notifier).track(widget.product.id);
    });
    // Refresh user address text so the delivery hint at the top is current.
    Future.microtask(() {
      if (!mounted) return;
      legacy.Provider.of<AddressService>(context, listen: false)
          .getAddress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productByIdStreamProvider(widget.product.id));
    // Use the realtime product when available, otherwise the bootstrap one.
    final product = async.valueOrNull ?? widget.product;
    final isFreshLoading =
        async.isLoading && async.valueOrNull == null && !async.hasError;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: isFreshLoading
          ? _DetailScaffold(
              productId: widget.product.id,
              child: const ProductDetailShimmer(),
            )
          : _DetailScaffold(
              productId: product.id,
              productNameForShare: product.name,
              priceForShare: product.price,
              child: _DetailBody(product: product),
            ),
      bottomNavigationBar:
          isFreshLoading ? null : CartActionBar(product: product),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.child,
    required this.productId,
    this.productNameForShare,
    this.priceForShare,
  });
  final Widget child;
  final String productId;
  final String? productNameForShare;
  final double? priceForShare;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: _FloatingTopBar(
              productId: productId,
              productNameForShare: productNameForShare,
              priceForShare: priceForShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTopBar extends ConsumerWidget {
  const _FloatingTopBar({
    required this.productId,
    this.productNameForShare,
    this.priceForShare,
  });

  final String productId;
  final String? productNameForShare;
  final double? priceForShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIcon(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        Row(
          children: [
            _CircleIcon(
              icon: Icons.share_outlined,
              onTap: () async {
                final name = productNameForShare ?? 'this product';
                final price = priceForShare;
                final priceText = price != null
                    ? ' — ₹${price.toStringAsFixed(0)}'
                    : '';
                await Share.share(
                  'Check out $name on QuickGrocery$priceText',
                );
              },
            ),
            const SizedBox(width: 8),
            if (productId.isNotEmpty)
              _FavoriteButton(productId: productId),
          ],
        ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav =
        ref.watch(isFavoriteStreamProvider(productId)).valueOrNull ?? false;
    return _CircleIcon(
      icon: fav ? Icons.favorite : Icons.favorite_border,
      onTap: () async {
        try {
          await ref
              .read(productDetailRepositoryProvider)
              .toggleFavorite(productId, !fav);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                fav ? 'Removed from favorites' : 'Added to favorites',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in required to favorite items.'),
            ),
          );
        }
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Body
// ──────────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = ref.watch(pricingConfigProvider).asData?.value;
    return CustomScrollView(
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 56),
          sliver: SliverToBoxAdapter(
            child: ProductImageCarousel(product: product),
          ),
        ),
        SliverToBoxAdapter(child: _ProductHeader(product: product)),
        SliverToBoxAdapter(child: ProductVariantWidget(product: product)),
        if (pricing != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  DeliveryPricingPolicy.productEligibilityLine(pricing),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 24),
          ),
        ),
        SliverToBoxAdapter(child: _PerksRow()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 24),
          ),
        ),
        SliverToBoxAdapter(child: _DescriptionSection(product: product)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 24),
          ),
        ),
        SliverToBoxAdapter(child: _ReviewsSection(productId: product.id)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 24),
          ),
        ),
        SliverToBoxAdapter(
          child: SimilarProductsSection(
            category: product.category,
            excludeId: product.id,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: RecentlyViewedSection(currentProductId: product.id),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _ProductHeader extends ConsumerWidget {
  const _ProductHeader({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(ratingSummaryProvider(product.id));
    final hasDiscount = product.hasDiscount;
    final stock = product.stock;
    final inStock = product.isAvailable && stock > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (productQuantityLabel(product).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    productQuantityLabel(product),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const Spacer(),
              _StockBadge(inStock: inStock, stock: stock),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          if (summary.total > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        summary.average.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${summary.total} ${'reviews'.tr()}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${(hasDiscount ? product.discountPrice : product.price).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${product.discountPercent}% OFF',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Inclusive of all taxes',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.inStock, required this.stock});
  final bool inStock;
  final int stock;

  @override
  Widget build(BuildContext context) {
    final color = inStock ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle : Icons.error,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            inStock
                ? (stock > 0 && stock < 10 ? 'Only $stock left' : 'In stock')
                : 'Out of stock',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _Perk(
              icon: Icons.local_shipping_outlined,
              title: 'Fast delivery',
              subtitle: '20 min',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Perk(
              icon: Icons.lock_outline_rounded,
              title: 'Secure',
              subtitle: 'payments',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Perk(
              icon: Icons.replay_circle_filled_outlined,
              title: 'No exchange',
              subtitle: 'or return',
            ),
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColor.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({required this.product});
  final ProductModel product;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final desc = widget.product.description.trim();
    if (desc.isEmpty) return const SizedBox.shrink();

    final isLong = desc.length > 280 || desc.split('\n').length > 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'description'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.topCenter,
            child: Text(
              desc,
              maxLines: _expanded ? null : 4,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.black87,
                height: 1.45,
              ),
            ),
          ),
          if (isLong)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Read less' : 'Read more',
                style: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(ratingsStreamProvider(productId));
    final summary = ref.watch(ratingSummaryProvider(productId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reviews'.tr(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ratingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Couldn\'t load reviews.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red.shade400,
                ),
              ),
            ),
            data: (ratings) {
              if (ratings.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReviewSummaryCard(summary: summary),
                  const SizedBox(height: 12),
                  ...ratings.take(5).map(
                    (r) => ProductReviewCard(rating: r),
                  ),
                  if (ratings.length > 5)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => DraggableScrollableSheet(
                              initialChildSize: 0.8,
                              maxChildSize: 0.95,
                              minChildSize: 0.4,
                              expand: false,
                              builder: (_, controller) => ListView.builder(
                                controller: controller,
                                padding: const EdgeInsets.all(16),
                                itemCount: ratings.length + 1,
                                itemBuilder: (_, i) {
                                  if (i == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        'All reviews',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  }
                                  return ProductReviewCard(
                                    rating: ratings[i - 1],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'See all ${ratings.length} reviews',
                          style: TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
