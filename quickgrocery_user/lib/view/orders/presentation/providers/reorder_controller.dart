import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';

import '../../domain/order_models.dart';

/// Hydrates a previous order's items back into the live cart.
///
/// Strategy:
///   1. For each `ProductItem` in the order, attempt to find the live
///      product by name (legacy orders don't store productId reliably).
///   2. If found and in stock, add it to the cart with the original
///      quantity (clamped to `maxOrder` / `stock`).
///   3. Track skipped items so the UI can warn the user.
class ReorderController {
  ReorderController(this._ref);

  final Ref _ref;

  Future<ReorderResult> reorder(LiveOrder order) async {
    final firestore = _ref.read(firebaseFirestoreProvider);
    final cart = _ref.read(cartProvider.notifier);

    final added = <String>[];
    final unavailable = <String>[];

    for (final item in order.legacy.products) {
      try {
        final query = await firestore
            .collection('products')
            .where('name', isEqualTo: item.name)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          unavailable.add(item.name);
          continue;
        }

        final doc = query.docs.first;
        final product = ProductModel.fromFirestore(doc.data(), doc.id);

        if (product.isOutOfStock) {
          unavailable.add(item.name);
          continue;
        }

        final cap = product.effectiveMaxQuantity;
        final qty = InventoryLimits.clampQuantity(
          requested: item.itemCount,
          stock: product.stock,
          maxOrder: product.maxOrder,
          minOrder: product.minOrderQuantity,
        );
        if (qty <= 0) {
          unavailable.add(item.name);
          continue;
        }

        if (!cart.addProduct(product)) {
          unavailable.add(item.name);
          continue;
        }
        for (var i = 1; i < qty; i++) {
          if (!cart.increment(product.id)) break;
        }
        added.add(item.name);
      } catch (_) {
        unavailable.add(item.name);
      }
    }

    return ReorderResult(added: added, unavailable: unavailable);
  }
}

class ReorderResult {
  final List<String> added;
  final List<String> unavailable;
  ReorderResult({required this.added, required this.unavailable});

  bool get fullySucceeded => unavailable.isEmpty && added.isNotEmpty;
  bool get nothingAdded => added.isEmpty;
}

final reorderControllerProvider = Provider<ReorderController>((ref) {
  return ReorderController(ref);
});
