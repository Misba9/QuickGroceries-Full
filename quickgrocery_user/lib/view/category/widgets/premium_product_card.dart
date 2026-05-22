import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/animated_add_button.dart';
import 'package:quickgrocery/core/widgets/discount_badge.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Premium grocery product card — Zepto / Blinkit / Instamart feel.
///
/// Layout (top → bottom):
/// 1. **Image surface** — square, soft-grey background, cached & rounded;
///    discount badge top-left, optional save heart top-right.
/// 2. **Unit chip** — compact "1 kg" tag (e.g. "500 g", "12 pcs").
/// 3. **Title** — single line, ellipsis, semibold.
/// 4. **Rating row** — star + average + review count (hidden if no rating).
/// 5. **Price + ADD** — current price + slashed price; right-aligned
///    [AnimatedAddButton] that swaps in a [QuantityStepper] on tap.
///
/// Uses Hero with tag `product-${id}` so opening the product detail
/// screen animates the image smoothly.
class PremiumProductCard extends StatelessWidget {
  const PremiumProductCard({
    super.key,
    required this.product,
    required this.count,
    required this.onTap,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final ProductModel product;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final discount = _discountPct();
    final outOfStock = product.isOutOfStock;
    final maxQty = product.effectiveMaxQuantity;

    return Opacity(
      opacity: outOfStock ? 0.55 : 1,
      child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppSurface.border),
            boxShadow: AppShadow.dim,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bounded = constraints.hasBoundedHeight &&
                    constraints.maxHeight < double.infinity;
                final image = _ImageSurface(
                  imageUrl: product.image,
                  heroTag: 'product-${product.id}',
                  discountPct: discount,
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
                    if (product.unitPerItem.isNotEmpty)
                      _UnitChip(text: product.unitPerItem),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppSurface.text,
                        height: 1.2,
                      ),
                    ),
                    if (product.rating > 0) ...[
                      const SizedBox(height: 4),
                      _RatingRow(
                        rating: product.rating,
                        reviews: product.totalReviews,
                      ),
                    ],
                    if (bounded) const Spacer() else const SizedBox(height: 6),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _PriceColumn(
                            price: product.price,
                            slashed: product.slashedPrice,
                          ),
                        ),
                        outOfStock
                            ? _OutOfStockPill()
                            : AnimatedAddButton(
                                count: count,
                                onAdd: onAdd,
                                onIncrement: onIncrement,
                                onDecrement: onDecrement,
                                maxQuantity: maxQty > 0 ? maxQty : null,
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

  int _discountPct() {
    if (product.slashedPrice <= 0) return 0;
    if (product.price <= 0) return 0;
    if (product.slashedPrice <= product.price) return 0;
    final pct =
        ((product.slashedPrice - product.price) / product.slashedPrice) * 100;
    return pct.round();
  }
}

// ─── Image surface with discount badge ──────────────────────────────────

class _ImageSurface extends StatelessWidget {
  const _ImageSurface({
    required this.imageUrl,
    required this.heroTag,
    required this.discountPct,
  });

  final String imageUrl;
  final String heroTag;
  final int discountPct;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppSurface.subtle,
              child: Hero(
                tag: heroTag,
                child: CachedImage(url: imageUrl, fit: BoxFit.cover),
              ),
            ),
            if (discountPct > 0)
              Positioned(
                top: 0,
                left: 0,
                child: DiscountBadge(percent: discountPct),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Unit chip ──────────────────────────────────────────────────────────

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppSurface.subtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppSurface.textSecondary,
          letterSpacing: 0.2,
          height: 1.2,
        ),
      ),
    );
  }
}

// ─── Rating row ────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.reviews});

  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF5A623)),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            rating.toStringAsFixed(1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppSurface.textSecondary,
              height: 1.2,
            ),
          ),
        ),
        if (reviews > 0) ...[
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '($reviews)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppSurface.textMuted,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Price column ──────────────────────────────────────────────────────

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({required this.price, required this.slashed});

  final double price;
  final double slashed;

  @override
  Widget build(BuildContext context) {
    final hasSlash = slashed > 0 && slashed > price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '₹${_fmt(price)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppSurface.text,
            height: 1.1,
          ),
        ),
        if (hasSlash)
          Text(
            '₹${_fmt(slashed)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppSurface.textMuted,
              decoration: TextDecoration.lineThrough,
              height: 1.2,
            ),
          ),
      ],
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

class _OutOfStockPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'OUT',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
