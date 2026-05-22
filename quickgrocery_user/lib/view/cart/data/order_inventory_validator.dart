import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/models/product.dart';
import '../domain/cart_models.dart';

/// Pre-checkout validation against live Firestore product docs.
class OrderInventoryValidator {
  OrderInventoryValidator(this._firestore);

  final FirebaseFirestore _firestore;

  /// Returns a user-facing error message, or null when every line is valid.
  Future<String?> validateLines(List<CartItem> items) async {
    if (items.isEmpty) return 'Your cart is empty';

    final ids = items.map((e) => e.productId).toSet().toList();
    final live = await _fetchProducts(ids);

    for (final line in items) {
      if (line.isComboLine) continue;

      final product = live[line.productId];
      if (product == null) {
        return 'Some items are no longer available';
      }

      if (InventoryLimits.isOutOfStock(
        stock: product.stock,
        isAvailable: product.isAvailable,
        stockStatus: product.stockStatus,
      )) {
        return 'Some items are out of stock';
      }

      final max = InventoryLimits.effectiveMaxQuantity(
        stock: product.stock,
        maxOrder: product.maxOrder,
      );
      if (line.itemCount > max) {
        return 'Some items exceed the maximum order limit';
      }

      if (product.minOrderQuantity > 0 &&
          line.itemCount < product.minOrderQuantity) {
        return 'Some items do not meet the minimum order quantity';
      }
    }
    return null;
  }

  Future<Map<String, ProductModel>> _fetchProducts(List<String> ids) async {
    final out = <String, ProductModel>{};
    const chunk = 30;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.sublist(i, i + chunk > ids.length ? ids.length : i + chunk);
      final snap = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: slice)
          .get();
      for (final doc in snap.docs) {
        out[doc.id] = ProductModel.fromFirestore(doc.data(), doc.id);
      }
    }
    return out;
  }
}
