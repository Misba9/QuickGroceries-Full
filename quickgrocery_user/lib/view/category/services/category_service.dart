import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/screens/addon_screen.dart';

class CategoryService extends ChangeNotifier {
  String _selectedCategory = '';
  String get selectedCategory => _selectedCategory;

  List<ProductModel> _products = [];
  List<ProductModel> selectedProduct = [];
  List<CategoryModel> categories = [];
  List<CategoryModel> subCategories = [];
  List<ProductModel> filteredProducts = [];
  String _searchQuery = '';
  List<ProductModel> allProducts = [];

  /// Lets newer cart plumbing rebuild legacy listeners without exposing
  /// `notifyListeners()` publicly across the whole codebase.
  void notifyCartListeners() => notifyListeners();

  // ─────────────────────────────
  // 🔹 When a main category changes
  // ─────────────────────────────
  void onCategoryChanged(String category) {
    _selectedCategory = category;
    notifyListeners();

    _products.clear();
    filteredProducts.clear();
    getProducts();
    // notifyListeners();

    // getSubCategories(category);
  }

  // ─────────────────────────────
  // 🔹 Fetch all products (for addon use)
  // ─────────────────────────────
  Future<void> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      allProducts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  // ─────────────────────────────
  // 🔹 Get filtered products (for search)
  // ─────────────────────────────
  List<ProductModel> get products =>
      _searchQuery.isEmpty ? _products : filteredProducts;

  void filterProducts(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      filteredProducts = _products;
    } else {
      filteredProducts = _products
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }

  // ─────────────────────────────
  // 🔹 Fetch subcategories for a main category
  // ─────────────────────────────
  Future<void> getSubCategories(String mainCategory) async {
    try {
      // Clear old data
      subCategories.clear();
      _products.clear();
      filteredProducts.clear();
      _selectedCategory = '';

      // Get subcategories - try with orderBy first, fallback without if index missing
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('subcategories')
            .where('main_category', isEqualTo: mainCategory)
            .orderBy('order')
            .get();
      } catch (e) {
        // If orderBy fails (missing index), try without it
        log("OrderBy failed, trying without order: $e");
        snapshot = await FirebaseFirestore.instance
            .collection('subcategories')
            .where('main_category', isEqualTo: mainCategory)
            .get();
      }

      subCategories = snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      log("Found ${subCategories.length} subcategories for $mainCategory");

      // ✅ If subcategories exist → auto select the first one
      if (subCategories.isNotEmpty) {
        _selectedCategory = subCategories.first.name;
        log("Auto-selected subcategory: $_selectedCategory");
        await getProducts();
      } else {
        // ❗ No subcategories → fetch products directly under main category
        log("No subcategories found, fetching products by main_category");
        QuerySnapshot productSnapshot;

        try {
          // Try querying by main_category first
          productSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('main_category', isEqualTo: mainCategory)
              .where('is_active', isEqualTo: true)
              .get();
        } catch (e) {
          // If main_category field doesn't exist, try category field as fallback
          log("Query by main_category failed, trying category field: $e");
          try {
            productSnapshot = await FirebaseFirestore.instance
                .collection('products')
                .where('category', isEqualTo: mainCategory)
                .where('is_active', isEqualTo: true)
                .get();
          } catch (e2) {
            log("Query by category also failed: $e2");
            // If both fail, try without is_active filter
            productSnapshot = await FirebaseFirestore.instance
                .collection('products')
                .where('category', isEqualTo: mainCategory)
                .get();
          }
        }

        _products = productSnapshot.docs
            .map(
              (doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        filteredProducts = _products;
        log(
          "Found ${_products.length} products for main category $mainCategory",
        );
      }

      notifyListeners();
    } catch (e, stackTrace) {
      log("Error getting subcategories: $e");
      log("Stack trace: $stackTrace");
      // Ensure UI is updated even on error
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // 🔹 Show Addon popup when needed
  // ─────────────────────────────
  void showAddonPopupIfNeeded(BuildContext context, ProductModel mainProduct) {
    if (mainProduct.addonIds.isEmpty) return;

    final addonProducts = allProducts
        .where((p) => mainProduct.addonIds.contains(p.id))
        .toList();

    if (addonProducts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddonSelector(product: mainProduct, addons: addonProducts),
    );
  }

  // ─────────────────────────────
  // 🔹 Add a product
  // ─────────────────────────────
  /// Returns false when add was blocked (OOS / max order).
  bool addProduct(BuildContext context, ProductModel product) {
    if (product.isOutOfStock) return false;

    final index = selectedProduct.indexWhere((p) => p.id == product.id);
    final cap = product.effectiveMaxQuantity;

    if (index != -1) {
      final cur = selectedProduct[index];
      if (cur.itemCount >= cap) return false;
      cur.itemCount = (cur.itemCount + 1).clamp(1, cap);
      notifyListeners();
      return true;
    }

    showAddonPopupIfNeeded(context, product);
    final qty = InventoryLimits.clampQuantity(
      requested: product.minOrderQuantity > 1 ? product.minOrderQuantity : 1,
      stock: product.stock,
      maxOrder: product.maxOrder,
      minOrder: product.minOrderQuantity,
    );
    if (qty <= 0) return false;
    product.itemCount = qty;
    selectedProduct.add(product);
    notifyListeners();
    return true;
  }

  // ─────────────────────────────
  // 🔹 Add product directly without weight selector (for Buy Now flow)
  // ─────────────────────────────
  bool addProductDirectly(ProductModel product) {
    if (product.isOutOfStock) return false;

    final index = selectedProduct.indexWhere((p) => p.id == product.id);
    final cap = product.effectiveMaxQuantity;
    final requested = product.itemCount < 1 ? 1 : product.itemCount;
    final qty = InventoryLimits.clampQuantity(
      requested: requested,
      stock: product.stock,
      maxOrder: product.maxOrder,
      minOrder: product.minOrderQuantity,
    );
    if (qty <= 0) return false;

    if (index != -1) {
      final cur = selectedProduct[index];
      final next = (cur.itemCount + qty).clamp(1, cap);
      if (next == cur.itemCount) return false;
      cur.itemCount = next;
    } else {
      product.itemCount = qty;
      selectedProduct.add(product);
    }

    notifyListeners();
    return true;
  }

  // ─────────────────────────────
  // 🔹 Increment/Decrement product count
  // ─────────────────────────────
  /// Returns false when increment was blocked (max / stock).
  bool addProductCount(String id, {ProductModel? catalogProduct}) {
    final index = selectedProduct.indexWhere((p) => p.id == id);
    if (index == -1) return false;

    final line = selectedProduct[index];
    final stock = catalogProduct?.stock ?? line.stock;
    final maxOrder = catalogProduct?.maxOrder ?? line.maxOrder;
    final available = catalogProduct?.isAvailable ?? line.isAvailable;

    if (InventoryLimits.isOutOfStock(
      stock: stock,
      isAvailable: available,
      stockStatus: catalogProduct?.stockStatus,
    )) {
      return false;
    }

    final cap = InventoryLimits.effectiveMaxQuantity(
      stock: stock,
      maxOrder: maxOrder,
    );
    if (line.itemCount >= cap) return false;

    line.itemCount++;
    if (catalogProduct != null) {
      line.stock = catalogProduct.stock;
      line.maxOrder = catalogProduct.maxOrder;
      line.isAvailable = catalogProduct.isAvailable;
    }
    notifyListeners();
    return true;
  }

  void removeProductCount(String id) {
    ProductModel product = selectedProduct.firstWhere(
      (product) => product.id == id,
    );

    if (product.itemCount < 2) {
      selectedProduct.remove(product);
    } else {
      product.itemCount--;
    }

    notifyListeners();
  }

  // ─────────────────────────────
  // 🔹 Calculate total amount
  // ─────────────────────────────
  double getTotalAmount(
    int deliveryCharge,
    int? discountPercentage, {
    int platformFee = 0,
    int handlingCharge = 0,
  }) {
    // Calculate item total (before discount)
    // Use effectivePrice for vegetables (weight-based) or regular price for others
    double itemTotal = selectedProduct.fold(
      0.0,
      (sum, product) => sum + (product.effectivePrice * product.itemCount),
    );

    // Apply discount if any
    double totalAmount = itemTotal;
    if (discountPercentage != null) {
      double discountAmount = totalAmount * (discountPercentage / 100);
      totalAmount -= discountAmount;
    }

    // Free delivery logic - check on item total before discount
    int actualDeliveryCharge = deliveryCharge;
    if (itemTotal >= 99) {
      actualDeliveryCharge = 0;
    }

    totalAmount += actualDeliveryCharge;
    totalAmount += handlingCharge;
    totalAmount += platformFee;

    return double.parse(totalAmount.toStringAsFixed(2));
  }

  // ─────────────────────────────
  // 🔹 Fetch products of selected subcategory
  // ─────────────────────────────
  Future<void> getProducts() async {
    if (_selectedCategory.isEmpty) {
      log("getProducts called but _selectedCategory is empty");
      return;
    }

    try {
      log("Fetching products for subcategory: $_selectedCategory");
      QuerySnapshot snapshot;

      try {
        // Query by subcategory (camelCase) with is_active filter
        snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('subcategory', isEqualTo: _selectedCategory)
            .where('is_active', isEqualTo: true)
            .get();
      } catch (e) {
        // If query with is_active fails, try without filter
        log("Query with is_active failed, trying without filter: $e");
        snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('subcategory', isEqualTo: _selectedCategory)
            .get();
      }

      _products = snapshot.docs
          .map(
            (doc) => ProductModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      filteredProducts = _products;
      log(
        "Found ${_products.length} products for subcategory $_selectedCategory",
      );
      notifyListeners();
    } catch (e, stackTrace) {
      log("Error getting products: $e");
      log("Stack trace: $stackTrace");
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // 🔹 Fetch main categories
  // ─────────────────────────────
  Future<void> fetchCategories() async {
    if (categories.isEmpty) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .orderBy('order')
            .get();

        categories.clear();

        for (var doc in querySnapshot.docs) {
          categories.add(
            CategoryModel.fromJson(doc.data() as Map<String, dynamic>),
          );
        }

        notifyListeners();
      } catch (e) {
        log("Error fetching categories: $e");
      }
    }
  }
}
