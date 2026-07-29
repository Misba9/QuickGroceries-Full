import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/auth/guest_auth_guard.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/product/product_quantity_label.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/discount_badge.dart';
import 'package:quickgrocery/core/widgets/product_badges.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/utils/cart_quantity_actions.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/product_detail_providers.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';

/// Modern, Zepto/Blinkit-style product card used by every home rail and
/// the explore grid. Bridges the new dynamic homepage with the legacy
/// [CategoryService] so the cart continues to work end-to-end.
///
/// Hero transitions are **opt-in** via [heroTag]. Do not use a bare
/// `product-image-$id` tag here: [LandingScreen]'s [IndexedStack] keeps
/// Home + Categories mounted together, and the same product often appears
/// in multiple rails — duplicate tags throw and cascade into
/// `_dependents.isEmpty`.
class HomeProductCard extends ConsumerWidget {
  const HomeProductCard({
    super.key,
    required this.product,
    this.width = 150,
    this.onAfterProductDetailClosed,
    this.heroTag,
  });

  final ProductModel product;
  final double width;
  /// Called after the product detail route is popped (e.g. wishlist refresh).
  final VoidCallback? onAfterProductDetailClosed;

  /// Optional unique [Hero] tag for this card instance only. Must not collide
  /// with any other Hero in the current route subtree (including offstage
  /// [IndexedStack] tabs). Prefer `productHeroTag(id, scope: 'rail-$i')`.
  final String? heroTag;

  static const double _radius = AppRadii.lg;
  static const double _cardPadding = 8;
  /// Image area height on horizontal rails (unbounded height parent).
  static const double _railImageHeightFactor = 0.82;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartService = legacy.Provider.of<CategoryService>(context);
    final cart = ref.watch(cartProvider);
    final cartLine = cart.items
        .where((e) => e.productId == product.id && !e.isComboLine)
        .firstOrNull;
    final count = cartLine?.itemCount ?? 0;
    final outOfStock = product.isOutOfStock;
    final weightLabel = productQuantityLabel(product);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: AppShadow.card,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: Opacity(
            opacity: outOfStock ? 0.55 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(_radius),
              onTap: () async {
                HapticFeedback.selectionClick();
                await Navigator.push(
                  context,
                  AppPageRoutes.product(product, heroTag: heroTag),
                );
                onAfterProductDetailClosed?.call();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: AppSurface.border.withValues(alpha: 0.55),
                  ),
                ),
                padding: const EdgeInsets.all(_cardPadding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bounded = constraints.hasBoundedHeight &&
                        constraints.maxHeight < double.infinity;
                    final image = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _ImageWithDiscount(
                          product: product,
                          heroTag: heroTag,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _FavoriteChip(productId: product.id),
                        ),
                      ],
                    );

                    final details = _ProductDetails(
                      product: product,
                      weightLabel: weightLabel,
                      count: count,
                      onAdd: () {
                        final wasEmpty = count == 0;
                        tryAddProductToCart(
                          context,
                          ref,
                          product: product,
                          onAdded: wasEmpty
                              ? () => cartService.showAddonPopupIfNeeded(
                                    context,
                                    product,
                                  )
                              : null,
                        );
                      },
                      onIncrement: () => tryIncrementProductInCart(
                        context,
                        ref,
                        product: product,
                        legacyCart: cartService,
                      ),
                      onMaxReached: () => AppSnackBar.error(
                        maxQuantityMessageFor(context, product),
                        context: context,
                      ),
                      onDecrement: () {
                        ref.read(cartProvider.notifier).decrement(product.id);
                      },
                    );

                    if (bounded) {
                      return SizedBox(
                        height: constraints.maxHeight,
                        width: constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: image),
                            details,
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: width * _railImageHeightFactor,
                          child: image,
                        ),
                        details,
                      ],
                    );
                  },
                ),
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

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({
    required this.product,
    required this.weightLabel,
    required this.count,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onMaxReached,
  });

  final ProductModel product;
  final String weightLabel;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onMaxReached;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          if (weightLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              weightLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppSurface.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ],
          if (product.totalReviews > 0) ...[
            const SizedBox(height: 4),
            _RatingPill(
              rating: product.rating,
              reviews: product.totalReviews,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _PriceBlock(product: product)),
              _CartControl(
                product: product,
                count: count,
                onAdd: onAdd,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
                onMaxReached: onMaxReached,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          final authed = await GuestAuthGuard.requireAuth(context, ref);
          if (!authed || !context.mounted) return;
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
  const _ImageWithDiscount({required this.product, this.heroTag});

  final ProductModel product;
  final String? heroTag;

  static const double _innerR = 12;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedImage(
      url: product.image,
      fit: BoxFit.contain,
      borderRadius: BorderRadius.circular(_innerR - 2),
      memCacheWidth: 400,
    );
    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_innerR),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppSurface.subtle.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Center(child: image),
            ),
          ),
          if (product.hasDiscount)
            Positioned(
              top: 6,
              left: 6,
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
            height: 1.1,
          ),
        ),
        if (hasDiscount)
          Text(
            _money(product.price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: AppSurface.textSecondary,
              decoration: TextDecoration.lineThrough,
              height: 1.1,
            ),
          ),
      ],
    );
  }

  String _money(double v) =>
      '₹${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
}

class _CartControl extends StatelessWidget {
  const _CartControl({
    required this.product,
    required this.count,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onMaxReached,
  });

  final ProductModel product;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onMaxReached;

  static const double _h = 32;

  @override
  Widget build(BuildContext context) {
    if (product.isOutOfStock) {
      return Container(
        height: _h,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          context.l10n.outOfStock,
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

    final maxQty = product.effectiveMaxQuantity;
    final atMax = count >= maxQty;

    if (count == 0) {
      return Material(
        color: Colors.transparent,
        elevation: 3,
        shadowColor: AppColor.primary.withValues(alpha: 0.3),
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
          _StepBtn(
            icon: Icons.add,
            onTap: () {
              if (atMax) {
                onMaxReached();
              } else {
                onIncrement();
              }
            },
            disabled: false,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled || onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: SizedBox(
        width: 28,
        height: _CartControl._h,
        child: Icon(
          icon,
          color: disabled ? Colors.white54 : Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
