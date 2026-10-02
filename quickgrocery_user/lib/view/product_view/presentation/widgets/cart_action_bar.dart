import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/inventory/inventory_limit_messages.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/quantity_provider.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/fly_to_cart_animation.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/quantity_selector.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Bottom action bar for the product details screen.
///
/// Two visual states:
///  - When the product is **not yet** in the legacy cart, shows a stepper
///    plus a prominent "Add to cart" button which triggers a fly-to-cart
///    overlay animation, then morphs into the next state.
///  - Once added, shows a "Go to cart" button instead.
///
/// Cart state is owned by Riverpod [cartProvider] and bridged to legacy
/// services in [CartBootstrap] so existing checkout flow keeps working.
class CartActionBar extends ConsumerStatefulWidget {
  const CartActionBar({super.key, required this.product});
  final ProductModel product;

  @override
  ConsumerState<CartActionBar> createState() => _CartActionBarState();
}

class _CartActionBarState extends ConsumerState<CartActionBar> {
  final GlobalKey _imageKey = GlobalKey();

  Future<void> _addToCart() async {
    final qty = ref.read(
      quantityFor(
        productId: widget.product.id,
        stock: widget.product.stock,
        maxOrder: widget.product.maxOrder,
      ),
    );

    final weight = widget.product.isVegetable
        ? ref.read(productWeightProvider(widget.product.id))
        : widget.product.selectedWeightInGrams;

    // Build a fresh copy so cart mutations never touch the realtime model.
    final copy = widget.product.copyWith(
      itemCount: qty,
      selectedWeightInGrams: weight,
    );

    final added = ref.read(cartProvider.notifier).addProductDirectly(copy);
    if (!added) {
      if (!mounted) return;
      AppSnackBar.error(
        widget.product.isOutOfStock
            ? InventoryLimitMessages.outOfStock(context.l10n)
            : InventoryLimitMessages.incrementBlocked(
                l10n: context.l10n,
                stock: widget.product.stock,
                maxOrder: widget.product.maxOrder,
                currentCount: qty,
              ),
        context: context,
      );
      return;
    }

    if (context.mounted) {
      AppSnackBar.success(context.l10n.item_added_to_cart, context: context);
    }

    // Fly-to-cart animation, anchored on the bottom-bar thumbnail.
    final ctx = _imageKey.currentContext;
    if (ctx != null && widget.product.image.isNotEmpty) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final origin = box.localToGlobal(Offset.zero);
        final rect = Rect.fromLTWH(
          origin.dx,
          origin.dy,
          box.size.width,
          box.size.height,
        );
        // ignore: use_build_context_synchronously
        await FlyToCart.run(
          context,
          imageUrl: widget.product.image,
          startRect: rect,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final inCart = cart.items.any(
      (p) => p.productId == widget.product.id,
    );
    final unavailable =
        !widget.product.isAvailable || widget.product.stock == 0;

    final qty = ref.watch(
      quantityFor(
        productId: widget.product.id,
        stock: widget.product.stock,
        maxOrder: widget.product.maxOrder,
      ),
    );
    final weight = widget.product.isVegetable
        ? ref.watch(productWeightProvider(widget.product.id))
        : widget.product.selectedWeightInGrams;

    final unitPrice = widget.product.isVegetable
        ? (widget.product.hasDiscount
                  ? widget.product.discountPrice
                  : widget.product.price) *
              weight /
              1000.0
        : (widget.product.hasDiscount
              ? widget.product.discountPrice
              : widget.product.price);
    final total = unitPrice * qty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppSurface.of(context).card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkTheme ? 0.35 : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.product.image.isNotEmpty) ...[
            // Hidden anchor used by the fly-to-cart animation.
            Opacity(
              opacity: 0,
              child: SizedBox(
                key: _imageKey,
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (!inCart)
            QuantitySelector(
              value: qty,
              disabled: unavailable,
              onIncrement: () {
                final ok = quantityNotifier(
                  ref,
                  productId: widget.product.id,
                  stock: widget.product.stock,
                  maxOrder: widget.product.maxOrder,
                ).increment();
                if (!ok && context.mounted) {
                  AppSnackBar.error(
                    InventoryLimitMessages.incrementBlocked(
                      l10n: context.l10n,
                      stock: widget.product.stock,
                      maxOrder: widget.product.maxOrder,
                      currentCount: qty,
                    ),
                    context: context,
                  );
                }
              },
              onDecrement: () => quantityNotifier(
                ref,
                productId: widget.product.id,
                stock: widget.product.stock,
                maxOrder: widget.product.maxOrder,
              ).decrement(),
            ),
          if (!inCart) const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              child: unavailable
                  ? _OutOfStockButton(key: const ValueKey('oos'))
                  : (inCart
                        ? _GoToCartButton(key: const ValueKey('go'))
                        : _AddToCartButton(
                            key: const ValueKey('add'),
                            total: total,
                            onTap: _addToCart,
                          )),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({
    super.key,
    required this.total,
    required this.onTap,
  });

  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Add to cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '₹${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoToCartButton extends StatelessWidget {
  const _GoToCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, AppPageRoutes.cart());
        },
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(
              'Go to cart',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutOfStockButton extends StatelessWidget {
  const _OutOfStockButton({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: surface.subtle,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'Out of stock',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: surface.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}
