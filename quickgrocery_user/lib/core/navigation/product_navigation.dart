import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';

/// Opens [ProductViewScreen] for a known product or by Firestore id.
///
/// Offer/banner redirects used to look up only [CategoryService.allProducts]
/// (capped ~300 docs) and silently no-op when missing — that made discounted /
/// featured offer taps feel broken. This helper always falls back to
/// `products/{id}`.
abstract final class ProductNavigation {
  ProductNavigation._();

  static String? _inflightKey;
  static DateTime? _inflightAt;

  static bool _shouldIgnoreDuplicate(String key) {
    final now = DateTime.now();
    if (_inflightKey == key &&
        _inflightAt != null &&
        now.difference(_inflightAt!) < const Duration(milliseconds: 800)) {
      return true;
    }
    return false;
  }

  static void _mark(String key) {
    _inflightKey = key;
    _inflightAt = DateTime.now();
  }

  static void _clear(String key) {
    if (_inflightKey == key) {
      _inflightKey = null;
      _inflightAt = null;
    }
  }

  /// Normalize admin redirect strings: `Product`, `product_page`, etc.
  static String normalizeRedirectType(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    if (t.isEmpty || t == 'none') return 'none';
    if (t == 'product' || t == 'product_page' || t == 'products') {
      return 'product';
    }
    if (t == 'category' || t == 'category_page' || t == 'categories') {
      return 'category';
    }
    if (t == 'offers' || t == 'offers_page' || t == 'offer') {
      return 'offers_page';
    }
    if (t == 'url' || t == 'link' || t == 'external') return 'url';
    return t;
  }

  static String? resolveProductId({
    String? redirectId,
    String? productId,
    String? id,
    String? sku,
  }) {
    for (final candidate in [redirectId, productId, id, sku]) {
      final v = candidate?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  /// Push product details for an already-loaded [product].
  static Future<void> openProduct(
    BuildContext context,
    ProductModel product, {
    String? heroTag,
  }) async {
    final id = product.id.trim();
    if (id.isEmpty) return;
    final key = 'product:$id';
    if (_shouldIgnoreDuplicate(key)) return;
    _mark(key);
    try {
      HapticFeedback.selectionClick();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        AppPageRoutes.product(product, heroTag: heroTag),
      );
    } finally {
      _clear(key);
    }
  }

  /// Resolve product from local cache, then Firestore, then open details.
  static Future<bool> openProductById(
    BuildContext context,
    String? productId, {
    String? heroTag,
    bool showError = true,
  }) async {
    final id = productId?.trim() ?? '';
    if (id.isEmpty) {
      if (showError && context.mounted) {
        AppSnackBar.error('Product unavailable', context: context);
      }
      return false;
    }

    final key = 'product:$id';
    if (_shouldIgnoreDuplicate(key)) return false;
    _mark(key);

    try {
      HapticFeedback.selectionClick();

      ProductModel? product;
      try {
        final cartService =
            legacy.Provider.of<CategoryService>(context, listen: false);
        for (final p in cartService.allProducts) {
          if (p.id == id) {
            product = p;
            break;
          }
        }
      } catch (_) {
        // CategoryService may be unavailable outside MultiProvider trees.
      }

      product ??= await fetchProductById(id);

      if (product == null) {
        if (kDebugMode) {
          debugPrint('[ProductNavigation] product not found id=$id');
        }
        if (showError && context.mounted) {
          AppSnackBar.error('Product not found', context: context);
        }
        return false;
      }

      if (!context.mounted) return false;
      await Navigator.of(context).push(
        AppPageRoutes.product(product, heroTag: heroTag),
      );
      return true;
    } finally {
      _clear(key);
    }
  }

  static Future<ProductModel?> fetchProductById(String productId) async {
    final id = productId.trim();
    if (id.isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .doc(id)
          .get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return ProductModel.fromFirestore(data, snap.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProductNavigation] fetch failed id=$id error=$e');
      }
      return null;
    }
  }
}
