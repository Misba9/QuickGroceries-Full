import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/animated_add_button.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/core/widgets/quantity_stepper.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/category/widgets/category_search_bar.dart';
import 'package:quickgrocery/view/category/widgets/category_sidebar_tile.dart';
import 'package:quickgrocery/view/category/widgets/premium_product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';

/// Premium **Category Products** screen — Zepto / Blinkit / Instamart
/// inspired layout.
///
/// Structure (top → bottom):
///   1. Sliver app bar — back, category title, sticky pinned.
///   2. Inline search bar — pinned beneath the title.
///   3. Two-pane body:
///        * left  — compact sub-category rail (sticky)
///        * right — responsive premium product grid
///   4. Floating "View cart" pill (shared with the home tab) anchored
///      above the safe-area inset, shown only when the cart has items.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final String category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      legacy.Provider.of<CategoryService>(context, listen: false)
          .getSubCategories(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(category: widget.category),
                const Expanded(child: _Body()),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: FloatingCartPill(),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Header — back, title, sticky search
// ──────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadow.dim,
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppSurface.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CategorySearchBar(
              hint: 'Search in $category',
              onChanged: (q) => legacy.Provider.of<CategoryService>(
                context,
                listen: false,
              ).filterProducts(q),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Body — split into rail + grid
// ──────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return legacy.Consumer<CategoryService>(
      builder: (context, p, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Sidebar(),
            const VerticalDivider(width: 1, color: AppSurface.border),
            Expanded(
              child: _Grid(
                products: p.products,
                isLoading: p.subCategories.isNotEmpty &&
                    p.products.isEmpty &&
                    p.selectedCategory.isNotEmpty,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Sidebar ─────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: const Color(0xFFFAFAFB),
      child: legacy.Consumer<CategoryService>(
        builder: (context, p, _) {
          if (p.subCategories.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 6,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppSurface.subtle,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 50,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppSurface.subtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: p.subCategories.length,
            itemBuilder: (context, i) {
              final c = p.subCategories[i];
              return CategorySidebarTile(
                image: c.image,
                title: c.name,
                isSelected: p.selectedCategory == c.name,
                onTap: () => p.onCategoryChanged(c.name),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Grid ────────────────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  const _Grid({required this.products, required this.isLoading});

  final List products;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: HomeShimmer.exploreGrid(count: 6),
      );
    }

    if (products.isEmpty) {
      return _Empty();
    }

    return legacy.Consumer<CategoryService>(
      builder: (context, p, _) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 110),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            // Card content (image + chip + title + rating + price + ADD)
            // needs ~280 dp at ~139 dp wide → ratio ~0.50 with breathing room
            // for one-line vs two-line titles and presence/absence of rating.
            childAspectRatio: 0.50,
          ),
          itemCount: p.products.length,
          itemBuilder: (context, i) {
            final product = p.products[i];
            final selected = p.selectedProduct.firstWhere(
              (e) => e.id == product.id,
              orElse: () => product,
            );
            final inCart = p.selectedProduct.any((e) => e.id == product.id);
            final count = inCart ? selected.itemCount : 0;

            return PremiumProductCard(
              product: product,
              count: count,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductViewScreen(product: product),
                ),
              ),
              onAdd: () => p.addProduct(context, product),
              onIncrement: () => p.addProductCount(product.id),
              onDecrement: () => p.removeProductCount(product.id),
            );
          },
        );
      },
    );
  }
}

// ── Empty ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 180,
              child: LottieBuilder.asset('assets/lottie/no_data.json'),
            ),
            const SizedBox(height: 12),
            Text(
              'no_products_found'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppSurface.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different category or search term.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppSurface.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Legacy `ProductCard` adapter
// ──────────────────────────────────────────────────────────────────────────
//
// Older callers (cart, search, wishlist, "you might also like" rail) still
// import this widget by name from `category_screen.dart`. We keep its
// public API exactly as it was — primitives in, callbacks out — but the
// internals now use the same premium look as [PremiumProductCard]:
// cached image, discount badge, unit chip, animated ADD ↔ stepper.
//
// This means upgrading any of those screens later is a no-op aesthetically
// because they're already on the new design system.

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.slashedPrice,
    required this.isSelected,
    required this.onSelect,
    required this.itemCount,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTap,
    required this.itemQuantity,
  });

  final String image;
  final String name;
  final String price;
  final String slashedPrice;
  final bool isSelected;
  final VoidCallback onSelect;
  final String itemCount;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onTap;
  final String itemQuantity;

  @override
  Widget build(BuildContext context) {
    final priceVal = double.tryParse(price) ?? 0;
    final slashVal = double.tryParse(slashedPrice) ?? 0;
    final hasSlash = slashVal > 0 && slashVal > priceVal;
    final discountPct = hasSlash
        ? ((slashVal - priceVal) / slashVal * 100).round()
        : 0;
    final count = isSelected ? (int.tryParse(itemCount) ?? 1) : 0;

    final card = Material(
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
                Widget imageStack() {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: AppSurface.subtle,
                          child: CachedImage(url: image, fit: BoxFit.cover),
                        ),
                        if (discountPct > 0)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppGradients.flashSale,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$discountPct% OFF',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final compactImage = SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: imageStack(),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:
                      bounded ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (bounded)
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: imageStack(),
                        ),
                      )
                    else
                      compactImage,
                    const SizedBox(height: 8),
                    if (itemQuantity.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppSurface.subtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          itemQuantity,
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
                      ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppSurface.text,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${_money(priceVal)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppSurface.text,
                                  height: 1.1,
                                ),
                              ),
                              if (hasSlash)
                                Text(
                                  '₹${_money(slashVal)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppSurface.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AnimatedAddButton(
                          count: count,
                          onAdd: onSelect,
                          onIncrement: onIncrement,
                          onDecrement: onDecrement,
                          size: QuantityStepperSize.small,
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
    );

    // When dropped into an unbounded-width parent (e.g. cart's
    // horizontal ListView), give the card a sensible default width.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite) return card;
        return SizedBox(width: 150, child: card);
      },
    );
  }

  String _money(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

