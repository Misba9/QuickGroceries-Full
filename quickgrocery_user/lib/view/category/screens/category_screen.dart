import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/category/widgets/category_search_bar.dart';
import 'package:quickgrocery/view/category/widgets/category_sidebar_tile.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';

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
            Positioned(
              left: 0,
              right: 0,
              bottom: FloatingCartPill.positionedBottomFullScreen(context),
              child: const FloatingCartPill(),
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: HomeShimmer.exploreGrid(count: 6),
      );
    }

    if (products.isEmpty) {
      return _Empty();
    }

        return legacy.Consumer<CategoryService>(
          builder: (context, p, _) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.64,
              ),
              itemCount: p.products.length,
              itemBuilder: (context, i) {
                final product = p.products[i];
                return LayoutBuilder(
                  builder: (context, c) {
                    return ProductCardWidget(
                      product: product,
                      width: c.maxWidth,
                    );
                  },
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
