import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/core/widgets/staggered_fade_in.dart';
import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/cart/presentation/utils/cart_quantity_actions.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/core/navigation/product_navigation.dart';

/// "Recently ordered" rail — surfaces unique items from the user's
/// past orders so reordering staples is one tap away.
///
/// Strategy:
///  - Listen to [userOrdersStreamProvider] (Step 4).
///  - Flatten products in chronological order, dedupe by name, take 10.
///  - Resolve each name against the legacy `CategoryService.products`
///    catalog so we can render a real product card with cart controls.
///  - Hide the rail when neither orders nor catalog have anything to show.
class RecentlyOrderedSection extends ConsumerWidget {
  const RecentlyOrderedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersStreamProvider);

    return ordersAsync.when(
      loading: () => _SectionFrame(
        child: Builder(
          builder: (context) => SkeletonRail(
            count: 4,
            height: Responsive.orderAgainRailHeight(context),
            itemWidth: 110,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();

        final namesSeen = <String>{};
        final List<_RecentItem> recent = [];
        for (final order in orders) {
          for (final p in order.legacy.products) {
            final name = p.name.trim().toLowerCase();
            if (name.isEmpty || !namesSeen.add(name)) continue;
            recent.add(_RecentItem(product: p));
            if (recent.length >= 10) break;
          }
          if (recent.length >= 10) break;
        }

        if (recent.isEmpty) return const SizedBox.shrink();

        return _SectionFrame(
          child: Builder(
            builder: (context) {
              final h = Responsive.orderAgainRailHeight(context);
              return HorizontalProductRail(
                height: h,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => StaggeredFadeIn(
                  index: i,
                  child: _RecentTile(item: recent[i]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Order again',
            actionLabel: 'View orders',
            onAction: () {
              legacy.Provider.of<HomeProvider>(context, listen: false)
                  .onSelectedChange(3);
            },
          ),
          child,
        ],
      ),
    );
  }
}

class _RecentItem {
  const _RecentItem({required this.product});
  final ProductItem product;
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item});
  final _RecentItem item;

  @override
  Widget build(BuildContext context) {
    final categoryService = legacy.Provider.of<CategoryService>(context);
    final ProductModel? canonical = _findCanonical(
      categoryService.allProducts.isNotEmpty
          ? categoryService.allProducts
          : const <ProductModel>[],
      item.product.name,
    );

    return SizedBox(
      width: 130,
      child: Material(
        color: Colors.white,
        borderRadius: AppRadii.all(AppRadii.md),
        elevation: 0,
        child: InkWell(
          borderRadius: AppRadii.all(AppRadii.md),
          onTap: () async {
            if (canonical == null) return;
            await ProductNavigation.openProduct(context, canonical);
          },
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: AppRadii.all(AppRadii.md),
              border: Border.all(color: AppSurface.of(context).border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight;
                      return Center(
                        child: SizedBox(
                          width: side,
                          height: side,
                          child: CachedImage(
                            url: item.product.image,
                            fit: BoxFit.contain,
                            borderRadius: AppRadii.all(AppRadii.sm),
                            memCacheWidth: 240,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppSurface.of(context).textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                _ReorderButton(canonical: canonical, fallback: item.product),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ProductModel? _findCanonical(List<ProductModel> all, String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return null;
    for (final p in all) {
      if (p.name.trim().toLowerCase() == lower) return p;
    }
    return null;
  }
}

class _ReorderButton extends ConsumerWidget {
  const _ReorderButton({required this.canonical, required this.fallback});
  final ProductModel? canonical;
  final ProductItem fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = legacy.Provider.of<CategoryService>(context);
    final product = canonical;
    final canAdd = product != null;
    final inCart = canAdd &&
        (ref.watch(cartProvider).items.any((e) => e.productId == product.id) ||
            cart.selectedProduct.any((p) => p.id == product.id));

    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: AppRadii.all(AppRadii.sm),
        onTap: !canAdd
            ? null
            : () {
                if (inCart) {
                  tryIncrementProductInCart(
                    context,
                    ref,
                    product: product,
                    legacyCart: cart,
                  );
                } else {
                  tryAddProductToCart(context, ref, product: product);
                }
              },
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: !canAdd
                ? AppSurface.of(context).subtle
                : AppColor.primary.withValues(alpha: 0.12),
            borderRadius: AppRadii.all(AppRadii.sm),
            border: Border.all(
              color: !canAdd
                  ? AppSurface.of(context).border
                  : AppColor.primary,
              width: 1,
            ),
          ),
          child: Text(
            inCart ? 'ADDED' : 'REORDER',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: !canAdd ? AppSurface.of(context).textMuted : AppColor.primary,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
