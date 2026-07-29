import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'dart:developer' as developer;

import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/inventory/inventory_limit_messages.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';

const bool _cartDiagLogs = true;

void _trace(String message) {
  if (!_cartDiagLogs) return;
  developer.log(message, name: 'CartActions');
}

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

  final legacyLine =
      legacyCart.selectedProduct.where((p) => p.id == product.id).firstOrNull;
  final current = line?.itemCount ?? legacyLine?.itemCount ?? 0;

  AppSnackBar.error(
    InventoryLimitMessages.incrementBlocked(
      l10n: context.l10n,
      stock: line?.stock ?? legacyLine?.stock ?? product.stock,
      maxOrder: line?.maxOrder ?? legacyLine?.maxOrder ?? product.maxOrder,
      currentCount: current,
    ),
    context: context,
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
  _trace('add pressed: productId=${product.id} name=${product.name}');
  if (ref.read(cartProvider.notifier).addProduct(product)) {
    final units = ref.read(cartProvider).totalUnits;
    _trace('add ok: totalUnits=$units popupCallback=${onAdded != null}');
    onAdded?.call();
    return true;
  }

  _trace('add blocked: productId=${product.id}');

  AppSnackBar.error(
    product.isOutOfStock
        ? InventoryLimitMessages.outOfStock(context.l10n)
        : InventoryLimitMessages.incrementBlocked(
            l10n: context.l10n,
            stock: product.stock,
            maxOrder: product.maxOrder,
            currentCount: product.effectiveMaxQuantity,
          ),
    context: context,
  );
  return false;
}

String maxQuantityMessageFor(BuildContext context, ProductModel product) =>
    InventoryLimitMessages.atMaxHint(
      l10n: context.l10n,
      stock: product.stock,
      maxOrder: product.maxOrder,
    );
