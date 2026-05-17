import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/product/product_quantity_label.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/discount_badge.dart';
import 'package:quickgrocery/core/widgets/product_badges.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/product_detail_providers.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_image_carousel.dart'
    show productHeroTag;
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';

/// Modern, Zepto/Blinkit-style product card used by every home rail and
/// the explore grid. Bridges the new dynamic homepage with the legacy
/// [CategoryService] so the cart continues to work end-to-end.
class HomeProductCard extends ConsumerWidget {
  const HomeProductCard({
    super.key,
    required this.product,
    this.width = 150,
    this.onAfterProductDetailClosed,
  });

  final ProductModel product;
  final double width;
  /// Called after the product detail route is popped (e.g. wishlist refresh).
  final VoidCallback? onAfterProductDetailClosed;

  static const double _radius = AppRadii.lg;
  static const double _elevation = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = legacy.Provider.of<CategoryService>(context);
    final selected = cartService.selectedProduct.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product,
    );
    final inCart = cartService.selectedProduct.any((p) => p.id == product.id);
    final count = inCart ? selected.itemCount : 0;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: _elevation * 2,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: _elevation,
              spreadRadius: -1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(_radius),
            onTap: () async {
              HapticFeedback.selectionClick();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductViewScreen(product: product),
                ),
              );
              onAfterProductDetailClosed?.call();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: AppSurface.border.withValues(alpha: 0.65)),
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bounded = constraints.hasBoundedHeight &&
                      constraints.maxHeight < double.infinity;
                  final image = Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ImageWithDiscount(product: product),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _FavoriteChip(productId: product.id),
                      ),
                    ],
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        bounded ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      if (bounded)
                        Expanded(child: image)
                      else
                        image,
                      const SizedBox(height: 8),
                      _Quantity(text: productQuantityLabel(product)),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppSurface.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      if (product.totalReviews > 0) ...[
                        const SizedBox(height: 4),
                        _RatingPill(
                          rating: product.rating,
                          reviews: product.totalReviews,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _PriceBlock(product: product)),
                          _CartControl(
                            product: product,
                            count: count,
                            onAdd: () =>
                                cartService.addProduct(context, product),
                            onIncrement: () =>
                                cartService.addProductCount(product.id),
                            onDecrement: () =>
                                cartService.removeProductCount(product.id),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Same widget as [HomeProductCard] — use this name in category/search grids.
typedef ProductCardWidget = HomeProductCard;

class _FavoriteChip extends ConsumerWidget {
  const _FavoriteChip({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(isFavoriteStreamProvider(productId));
    final fav = favAsync.valueOrNull ?? false;
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 1,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          HapticFeedback.selectionClick();
          await ref.read(productDetailRepositoryProvider).toggleFavorite(
                productId,
                !fav,
              );
        },
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 17,
            color: fav ? Colors.redAccent : Colors.black45,
          ),
        ),
      ),
    );
  }
}

class _ImageWithDiscount extends StatelessWidget {
  const _ImageWithDiscount({required this.product});

  final ProductModel product;

  static const double _innerR = 14;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_innerR),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppSurface.subtle.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Hero(
                  tag: productHeroTag(product.id),
                  child: CachedImage(
                    url: product.image,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.circular(_innerR - 4),
                    memCacheWidth: 360,
                  ),
                ),
              ),
            ),
            if (product.hasDiscount)
              Positioned(
                top: 0,
                left: 0,
                child: DiscountBadge(percent: product.discountPercent),
              ),
            Positioned(
              left: 4,
              bottom: 4,
              right: 4,
              child: ProductBadgesRow(product: product, maxBadges: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Quantity extends StatelessWidget {
  const _Quantity({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 10.5,
        color: AppSurface.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating, required this.reviews});

  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 11, color: Colors.green),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              rating.toStringAsFixed(1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '($reviews)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;
    final price = hasDiscount ? product.discountPrice : product.price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _money(price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppSurface.textPrimary,
          ),
        ),
        if (hasDiscount)
          Text(
            _money(product.price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppSurface.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  String _money(double v) => '₹${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
}

class _CartControl extends StatelessWidget {
  const _CartControl({
    required this.product,
    required this.count,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final ProductModel product;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  static const double _h = 32;

  @override
  Widget build(BuildContext context) {
    if (!product.isAvailable || product.stock == 0) {
      return Container(
        height: _h,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'OUT',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    if (count == 0) {
      return Material(
        color: Colors.transparent,
        elevation: 4,
        shadowColor: AppColor.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            onAdd();
          },
          child: Container(
            height: _h,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColor.primary.withValues(alpha: 0.14),
                  AppColor.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.primary, width: 1.2),
            ),
            child: Text(
              'ADD',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColor.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: _h,
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadow.dim,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove, onTap: onDecrement),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Padding(
              key: ValueKey(count),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 28,
        height: _CartControl._h,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
