import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/feedback/show_top_error_toast.dart';
import 'package:quickgrocery/core/inventory/inventory_limit_messages.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';

/// Tries Riverpod cart first, then legacy [CategoryService], and shows a top
/// error toast when increment is blocked by stock / max-order rules.
bool tryIncrementProductInCart(
  BuildContext context,
  WidgetRef ref, {
  required ProductModel product,
  CategoryService? legacyCart,
}) {
  final cart = ref.read(cartProvider);
  final line = cart.items
      .where((e) => e.productId == product.id && !e.isComboLine)
      .firstOrNull;

  if (ref.read(cartProvider.notifier).increment(product.id)) {
    return true;
  }

  legacyCart ??= legacy.Provider.of<CategoryService>(context, listen: false);
  if (legacyCart.addProductCount(product.id, catalogProduct: product)) {
    return true;
  }

  final legacyLine =
      legacyCart.selectedProduct.where((p) => p.id == product.id).firstOrNull;
  final current = line?.itemCount ?? legacyLine?.itemCount ?? 0;

  showTopErrorToast(
    context,
    InventoryLimitMessages.incrementBlocked(
      stock: line?.stock ?? legacyLine?.stock ?? product.stock,
      maxOrder: line?.maxOrder ?? legacyLine?.maxOrder ?? product.maxOrder,
      currentCount: current,
    ),
  );
  return false;
}

/// Adds one unit (or min order qty) via [CartNotifier.addProduct].
bool tryAddProductToCart(
  BuildContext context,
  WidgetRef ref, {
  required ProductModel product,
  VoidCallback? onAdded,
}) {
  if (ref.read(cartProvider.notifier).addProduct(product)) {
    onAdded?.call();
    return true;
  }

  showTopErrorToast(
    context,
    product.isOutOfStock
        ? InventoryLimitMessages.outOfStock
        : InventoryLimitMessages.incrementBlocked(
            stock: product.stock,
            maxOrder: product.maxOrder,
            currentCount: product.effectiveMaxQuantity,
          ),
  );
  return false;
}

String maxQuantityMessageFor(ProductModel product) =>
    InventoryLimitMessages.atMaxHint(
      stock: product.stock,
      maxOrder: product.maxOrder,
    );
