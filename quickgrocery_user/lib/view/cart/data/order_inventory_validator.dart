import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/l10n/app_localizations.dart';
import 'package:quickgrocery/core/localization/app_locales.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/inventory/inventory_limit_messages.dart';
import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/models/product.dart';
import '../domain/cart_models.dart';

/// Pre-checkout validation against live Firestore product docs.
class OrderInventoryValidator {
  OrderInventoryValidator(this._firestore);

  final FirebaseFirestore _firestore;

  /// Returns a user-facing error message, or null when every line is valid.
  Future<String?> validateLines(
    List<CartItem> items, {
    AppLocalizations? l10n,
  }) async {
    final result = await validateCheckout(items, l10n: l10n);
    return result.errorMessage;
  }

  Future<CheckoutValidationResult> validateCheckout(
    List<CartItem> items, {
    AppLocalizations? l10n,
  }) async {
    final strings = l10n ?? lookupAppLocalizations(AppLocales.fallback);
    if (items.isEmpty) {
      return CheckoutValidationResult(
        products: const [],
        vendors: const [],
        errorMessage: strings.cartEmptyMessage,
      );
    }

    final ids = items.map((e) => e.productId).toSet().toList();
    final live = await _fetchProducts(ids);
    final products = <ProductValidationSnapshot>[];
    String? error;

    for (final line in items) {
      if (line.isComboLine) continue;

      final product = live[line.productId];
      if (product == null) {
        error ??= '${line.name} is no longer available';
        products.add(
          ProductValidationSnapshot(
            productId: line.productId,
            name: line.name,
            isAvailable: false,
            stock: 0,
            requestedQuantity: line.itemCount,
            vendorId: line.vendorId,
            exists: false,
          ),
        );
        continue;
      }

      products.add(
        ProductValidationSnapshot(
          productId: product.id,
          name: product.name.isEmpty ? line.name : product.name,
          isAvailable: product.isAvailable,
          stock: product.stock,
          requestedQuantity: line.itemCount,
          vendorId: product.vendorId.isNotEmpty
              ? product.vendorId
              : line.vendorId,
          exists: true,
        ),
      );

      if (InventoryLimits.isOutOfStock(
        stock: product.stock,
        isAvailable: product.isAvailable,
        stockStatus: product.stockStatus,
      )) {
        error ??= product.isAvailable
            ? '${product.name} is out of stock'
            : '${product.name} is unavailable';
      }

      final max = InventoryLimits.effectiveMaxQuantity(
        stock: product.stock,
        maxOrder: product.maxOrder,
      );
      if (line.itemCount > max) {
        final label = product.name.isEmpty ? line.name : product.name;
        error ??=
            '$label: ${InventoryLimitMessages.incrementBlocked(l10n: strings, stock: product.stock, maxOrder: product.maxOrder, currentCount: max)}';
      }

      if (product.minOrderQuantity > 0 &&
          line.itemCount < product.minOrderQuantity) {
        error ??=
            '${product.name} minimum order quantity is ${product.minOrderQuantity}';
      }
    }

    final vendorIds = products
        .map((p) => p.vendorId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();
    final vendors = await _fetchVendors(vendorIds);

    for (final product in products) {
      if (product.vendorId.trim().isEmpty) {
        error ??= 'Vendor is missing for ${product.name}';
        continue;
      }
      final vendor = vendors[product.vendorId];
      if (vendor == null || !vendor.exists) {
        error ??= 'Vendor not found for ${product.name}';
        continue;
      }
      if (!vendor.isApproved) {
        error ??= 'Vendor is not approved';
        continue;
      }
      if (!vendor.isActive) {
        error ??= 'Vendor is inactive';
        continue;
      }
      if (!vendor.isOpen) {
        error ??= 'Vendor is closed';
        continue;
      }
    }

    return CheckoutValidationResult(
      products: products,
      vendors: vendors.values.toList(growable: false),
      errorMessage: error,
    );
  }

  Future<Map<String, ProductModel>> _fetchProducts(List<String> ids) async {
    final out = <String, ProductModel>{};
    const chunk = 30;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.sublist(
        i,
        i + chunk > ids.length ? ids.length : i + chunk,
      );
      final snap = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: slice)
          .get(const GetOptions(source: Source.server));
      for (final doc in snap.docs) {
        out[doc.id] = ProductModel.fromFirestore(doc.data(), doc.id);
      }
    }
    return out;
  }

  Future<Map<String, VendorValidationSnapshot>> _fetchVendors(
    List<String> ids,
  ) async {
    final out = <String, VendorValidationSnapshot>{};
    const chunk = 30;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.sublist(
        i,
        i + chunk > ids.length ? ids.length : i + chunk,
      );
      final snap = await _firestore
          .collection('vendors')
          .where(FieldPath.documentId, whereIn: slice)
          .get(const GetOptions(source: Source.server));
      for (final doc in snap.docs) {
        out[doc.id] = VendorValidationSnapshot.fromFirestore(
          doc.id,
          doc.data(),
        );
      }
    }

    for (final id in ids) {
      out.putIfAbsent(id, () => VendorValidationSnapshot.missing(id));
    }
    return out;
  }
}

@immutable
class CheckoutValidationResult {
  const CheckoutValidationResult({
    required this.products,
    required this.vendors,
    this.errorMessage,
  });

  final List<ProductValidationSnapshot> products;
  final List<VendorValidationSnapshot> vendors;
  final String? errorMessage;

  ProductValidationSnapshot? get firstProduct =>
      products.isEmpty ? null : products.first;

  VendorValidationSnapshot? get firstVendor =>
      vendors.isEmpty ? null : vendors.first;
}

@immutable
class ProductValidationSnapshot {
  const ProductValidationSnapshot({
    required this.productId,
    required this.name,
    required this.isAvailable,
    required this.stock,
    required this.requestedQuantity,
    required this.vendorId,
    required this.exists,
  });

  final String productId;
  final String name;
  final bool isAvailable;
  final int stock;
  final int requestedQuantity;
  final String vendorId;
  final bool exists;
}

@immutable
class VendorValidationSnapshot {
  const VendorValidationSnapshot({
    required this.vendorId,
    required this.isActive,
    required this.isApproved,
    required this.isOpen,
    required this.exists,
    required this.status,
  });

  factory VendorValidationSnapshot.missing(String vendorId) =>
      VendorValidationSnapshot(
        vendorId: vendorId,
        isActive: false,
        isApproved: false,
        isOpen: false,
        exists: false,
        status: 'missing',
      );

  factory VendorValidationSnapshot.fromFirestore(
    String vendorId,
    Map<String, dynamic> data,
  ) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final blocked =
        data['isBlocked'] == true ||
        data['is_blocked'] == true ||
        status == 'suspended' ||
        status == 'rejected';
    final active =
        !blocked &&
        data['is_active'] != false &&
        data['isActive'] != false &&
        status != 'inactive' &&
        status != 'pending';
    final approved = data.containsKey('isApproved')
        ? data['isApproved'] == true
        : data.containsKey('is_approved')
        ? data['is_approved'] == true
        : status != 'pending' && status != 'rejected';
    final open =
        data['isOpen'] != false &&
        data['is_open'] != false &&
        data['storeOpen'] != false &&
        data['store_open'] != false &&
        data['shopOpen'] != false;

    return VendorValidationSnapshot(
      vendorId: vendorId,
      isActive: active,
      isApproved: approved,
      isOpen: open,
      exists: true,
      status: status.isEmpty ? 'active' : status,
    );
  }

  final String vendorId;
  final bool isActive;
  final bool isApproved;
  final bool isOpen;
  final bool exists;
  final String status;
}
