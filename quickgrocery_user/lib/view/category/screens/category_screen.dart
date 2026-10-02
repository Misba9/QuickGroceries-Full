import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/theme/theme_system_ui.dart';
import 'package:quickgrocery/core/widgets/app_search_bar.dart';
import 'package:quickgrocery/core/widgets/sticky_search_bar.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/category/widgets/category_sidebar_tile.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

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
  final _searchController = TextEditingController();

  void _loadCategory() {
    _searchController.clear();
    legacy.Provider.of<CategoryService>(context, listen: false)
        .getSubCategories(widget.category);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategory());
  }

  @override
  void didUpdateWidget(covariant CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategory());
    }
  }

  void _onSubcategoryTap(CategoryService service, String name) {
    _searchController.clear();
    service.onCategoryChanged(name);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.of(context).background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: ThemeSystemUi.of(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                category: widget.category,
                searchController: _searchController,
              ),
              Expanded(
                child: _Body(
                  onSubcategoryTap: _onSubcategoryTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Header — back, title, sticky search
// ──────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.category,
    required this.searchController,
  });

  final String category;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppSurface.of(context).card,
        boxShadow: AppShadow.dim,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 12, 0),
            child: Row(
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
                      color: AppSurface.of(context).text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: StickySearchBar(
              elevated: true,
              searchBar: AppSearchBar(
                live: true,
                controller: searchController,
                hints: ['Search in $category'],
                onChanged: (q) => legacy.Provider.of<CategoryService>(
                  context,
                  listen: false,
                ).filterProducts(q),
              ),
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
  const _Body({required this.onSubcategoryTap});

  final void Function(CategoryService service, String name) onSubcategoryTap;

  @override
  Widget build(BuildContext context) {
    return legacy.Consumer<CategoryService>(
      builder: (context, p, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(onSubcategoryTap: onSubcategoryTap),
            VerticalDivider(width: 1, color: AppSurface.of(context).border),
            Expanded(
              child: _ProductPane(
                loadKey: p.loadGeneration,
                selectedCategory: p.selectedCategory,
                products: p.products,
                isLoading: p.isProductsLoading,
                hasError: p.productsState == CategoryProductsState.error,
                errorMessage: p.productsError,
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
  const _Sidebar({required this.onSubcategoryTap});

  final void Function(CategoryService service, String name) onSubcategoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: AppSurface.of(context).card,
      child: legacy.Consumer<CategoryService>(
        builder: (context, p, _) {
          if (p.isProductsLoading && p.subCategories.isEmpty) {
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
                        color: AppSurface.of(context).subtle,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      width: 50,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppSurface.of(context).subtle,
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
                onTap: () => onSubcategoryTap(p, c.name),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Product pane (category loader → grid with fade) ───────────────────────

class _ProductPane extends StatelessWidget {
  const _ProductPane({
    required this.loadKey,
    required this.selectedCategory,
    required this.products,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
  });

  final int loadKey;
  final String selectedCategory;
  final List products;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  static const _fadeDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isLoading) {
      child = AppLoading.section;
    } else if (hasError) {
      child = _LoadError(message: errorMessage);
    } else if (products.isEmpty) {
      child = _Empty();
    } else {
      child = legacy.Consumer<CategoryService>(
        builder: (context, p, _) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 9,
              childAspectRatio: 0.68,
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

    return AnimatedSwitcher(
      duration: _fadeDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey<String>(
          isLoading
              ? 'loading-$loadKey'
              : hasError
                  ? 'error-$loadKey'
                  : products.isEmpty
                      ? 'empty-$selectedCategory-$loadKey'
                      : 'grid-$selectedCategory-$loadKey',
        ),
        child: child,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              message ?? 'Could not load products',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppSurface.of(context).text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 180,
              child: LottieBuilder.asset('assets/lottie/no_data.json'),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.no_products_found,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppSurface.of(context).text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try a different category or search term.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppSurface.of(context).textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
