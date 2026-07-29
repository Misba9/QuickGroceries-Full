import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/screens/addon_screen.dart';

/// Product list fetch lifecycle for category / subcategory screens.
enum CategoryProductsState {
  idle,
  loading,
  ready,
  error,
}

class CategoryService extends ChangeNotifier {
  String _selectedCategory = '';
  String get selectedCategory => _selectedCategory;

  String _mainCategory = '';
  String get mainCategory => _mainCategory;

  List<ProductModel> _products = [];
  List<ProductModel> selectedProduct = [];
  List<CategoryModel> categories = [];
  List<CategoryModel> subCategories = [];
  List<ProductModel> filteredProducts = [];
  String _searchQuery = '';
  List<ProductModel> allProducts = [];

  CategoryProductsState _productsState = CategoryProductsState.idle;
  CategoryProductsState get productsState => _productsState;

  bool get isProductsLoading =>
      _productsState == CategoryProductsState.loading;

  String? _productsError;
  String? get productsError => _productsError;

  /// Bumped on every category/subcategory navigation — use as [ValueKey] for transitions.
  int _loadGeneration = 0;
  int get loadGeneration => _loadGeneration;

  /// Lets newer cart plumbing rebuild legacy listeners without exposing
  /// `notifyListeners()` publicly across the whole codebase.
  void notifyCartListeners() => notifyListeners();

  // ─────────────────────────────
  // 🔹 When a subcategory changes (sidebar tap)
  // ─────────────────────────────
  void onCategoryChanged(String category) {
    if (category.isEmpty) return;
    final generation = ++_loadGeneration;
    _selectedCategory = category;
    _productsState = CategoryProductsState.loading;
    _productsError = null;
    _products = [];
    filteredProducts = [];
    _searchQuery = '';
    notifyListeners();
    _fetchProductsForSubcategory(generation);
  }

  // ─────────────────────────────
  // 🔹 Fetch all products (for addon use)
  // ─────────────────────────────
  Future<void> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy(FieldPath.documentId)
          .limit(300)
          .get();

      allProducts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching products: $e");
    }
  }

  // ─────────────────────────────
  // 🔹 Get filtered products (for search)
  // ─────────────────────────────
  List<ProductModel> get products =>
      _searchQuery.isEmpty ? _products : filteredProducts;

  void filterProducts(String query) {
    if (_productsState == CategoryProductsState.loading) {
      return;
    }
    _searchQuery = query;
    if (query.isEmpty) {
      filteredProducts = List<ProductModel>.from(_products);
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

  void clearProductSearch() {
    _searchQuery = '';
    if (_products.isNotEmpty) {
      filteredProducts = List<ProductModel>.from(_products);
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // 🔹 Fetch subcategories for a main category
  // ─────────────────────────────
  Future<void> getSubCategories(String mainCategory) async {
    final generation = ++_loadGeneration;
    _mainCategory = mainCategory;
    _productsState = CategoryProductsState.loading;
    _productsError = null;
    subCategories = [];
    _selectedCategory = '';
    _products = [];
    filteredProducts = [];
    _searchQuery = '';
    notifyListeners();

    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('subcategories')
            .where('main_category', isEqualTo: mainCategory)
            .orderBy('order')
            .get();
      } catch (e) {
        log("OrderBy failed, trying without order: $e");
        snapshot = await FirebaseFirestore.instance
            .collection('subcategories')
            .where('main_category', isEqualTo: mainCategory)
            .get();
      }

      if (generation != _loadGeneration) return;

      subCategories = snapshot.docs
          .map(
            (doc) => CategoryModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      log("Found ${subCategories.length} subcategories for $mainCategory");

      if (subCategories.isNotEmpty) {
        _selectedCategory = subCategories.first.name;
        log("Auto-selected subcategory: $_selectedCategory");
        await _fetchProductsForSubcategory(generation);
      } else {
        log("No subcategories found, fetching products by main_category");
        await _fetchProductsForMainCategory(mainCategory, generation);
      }
    } catch (e, stackTrace) {
      if (generation != _loadGeneration) return;
      log("Error getting subcategories: $e");
      log("Stack trace: $stackTrace");
      _productsState = CategoryProductsState.error;
      _productsError = 'Could not load category';
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
    double itemTotal = selectedProduct.fold(
      0.0,
      (sum, product) => sum + (product.effectivePrice * product.itemCount),
    );

    double totalAmount = itemTotal;
    if (discountPercentage != null) {
      double discountAmount = totalAmount * (discountPercentage / 100);
      totalAmount -= discountAmount;
    }

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
  // 🔹 Fetch products of selected subcategory (public alias)
  // ─────────────────────────────
  Future<void> getProducts() async {
    if (_selectedCategory.isEmpty) {
      log("getProducts called but _selectedCategory is empty");
      return;
    }
    final generation = ++_loadGeneration;
    _productsState = CategoryProductsState.loading;
    _products = [];
    filteredProducts = [];
    _searchQuery = '';
    notifyListeners();
    await _fetchProductsForSubcategory(generation);
  }

  Future<void> _fetchProductsForSubcategory(int generation) async {
    final subcategory = _selectedCategory;
    if (subcategory.isEmpty) {
      if (generation != _loadGeneration) return;
      _productsState = CategoryProductsState.ready;
      notifyListeners();
      return;
    }

    try {
      log("Fetching products for subcategory: $subcategory");
      QuerySnapshot snapshot;

      try {
        snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('subcategory', isEqualTo: subcategory)
            .where('is_active', isEqualTo: true)
            .get();
      } catch (e) {
        log("Query with is_active failed, trying without filter: $e");
        snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('subcategory', isEqualTo: subcategory)
            .get();
      }

      if (generation != _loadGeneration || _selectedCategory != subcategory) {
        return;
      }

      _products = snapshot.docs
          .map(
            (doc) => ProductModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where((p) => p.isAvailable)
          .toList();

      filteredProducts = List<ProductModel>.from(_products);
      _productsState = CategoryProductsState.ready;
      _productsError = null;
      log("Found ${_products.length} products for subcategory $subcategory");
      notifyListeners();
    } catch (e, stackTrace) {
      if (generation != _loadGeneration || _selectedCategory != subcategory) {
        return;
      }
      log("Error getting products: $e");
      log("Stack trace: $stackTrace");
      _productsState = CategoryProductsState.error;
      _productsError = 'Could not load products';
      notifyListeners();
    }
  }

  Future<void> _fetchProductsForMainCategory(
    String mainCategory,
    int generation,
  ) async {
    try {
      QuerySnapshot productSnapshot;

      try {
        productSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('main_category', isEqualTo: mainCategory)
            .where('is_active', isEqualTo: true)
            .get();
      } catch (e) {
        log("Query by main_category failed, trying category field: $e");
        try {
          productSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: mainCategory)
              .where('is_active', isEqualTo: true)
              .get();
        } catch (e2) {
          log("Query by category also failed: $e2");
          productSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: mainCategory)
              .get();
        }
      }

      if (generation != _loadGeneration || _mainCategory != mainCategory) {
        return;
      }

      _products = productSnapshot.docs
          .map(
            (doc) => ProductModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where((p) => p.isAvailable)
          .toList();

      filteredProducts = List<ProductModel>.from(_products);
      _productsState = CategoryProductsState.ready;
      _productsError = null;
      log(
        "Found ${_products.length} products for main category $mainCategory",
      );
      notifyListeners();
    } catch (e, stackTrace) {
      if (generation != _loadGeneration || _mainCategory != mainCategory) {
        return;
      }
      log("Error fetching main category products: $e");
      log("Stack trace: $stackTrace");
      _productsState = CategoryProductsState.error;
      _productsError = 'Could not load products';
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

  void resetSessionForLogout() {
    selectedProduct.clear();
    notifyListeners();
  }
}
