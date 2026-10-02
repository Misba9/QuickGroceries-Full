import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/catalog/product_search.dart';
import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/core/startup/startup_isolate_parse.dart';
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
  Timer? _searchDebounce;

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
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    final generation = ++_loadGeneration;
    _selectedCategory = trimmed;
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
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy(FieldPath.documentId)
          .limit(300)
          .get();

      // Sanitize in chunks + model factories on a background isolate.
      allProducts = await StartupIsolateParse.parseProductsFromUntypedSnapshot(
        snapshot,
      );
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
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    // Empty query clears immediately; typing is debounced.
    if (trimmed.isEmpty) {
      _applyProductSearch('');
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      _applyProductSearch(trimmed);
    });
  }

  void _applyProductSearch(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      filteredProducts = List<ProductModel>.from(_products);
    } else {
      filteredProducts = _products
          .where(
            (product) => productMatchesSearchQuery(
              query,
              name: product.name,
              category: product.category,
              subcategory: product.subcategory,
              brand: product.brand,
              sku: product.sku,
              barcode: product.barcode,
              description: product.description,
            ),
          )
          .toList();
    }
    notifyListeners();
  }

  void clearProductSearch() {
    _searchDebounce?.cancel();
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
            (doc) => CategoryModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .where((c) => c.name.trim().isNotEmpty && c.isActive)
          .toList();

      log("Found ${subCategories.length} subcategories for $mainCategory");

      if (subCategories.isNotEmpty) {
        _selectedCategory = subCategories.first.name.trim();
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
    final subcategory = _selectedCategory.trim();
    if (subcategory.isEmpty) {
      if (generation != _loadGeneration) return;
      _productsState = CategoryProductsState.ready;
      notifyListeners();
      return;
    }

    try {
      log("Fetching products for subcategory: $subcategory");

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('subcategory', isEqualTo: subcategory)
          .get();

      var usedMainCategoryFallback = false;
      if (snapshot.docs.isEmpty && _mainCategory.trim().isNotEmpty) {
        log(
          "No exact subcategory docs for '$subcategory'; "
          "falling back to main '${_mainCategory.trim()}'",
        );
        snapshot = await _queryProductsForMainCategory(_mainCategory.trim());
        usedMainCategoryFallback = true;
      }

      if (generation != _loadGeneration ||
          _selectedCategory.trim() != subcategory) {
        return;
      }

      final needle = _norm(subcategory);
      final parsed =
          await StartupIsolateParse.parseProductsFromUntypedSnapshot(
        snapshot,
        onlyAvailable: true,
      );
      if (generation != _loadGeneration ||
          _selectedCategory.trim() != subcategory) {
        return;
      }

      _products = parsed.where((p) {
        if (!usedMainCategoryFallback) return true;
        final sub = _norm(p.subcategory);
        final cat = _norm(p.category);
        if (sub == needle) return true;
        // Legacy: no subcategory field, category equals sub name.
        if (sub.isEmpty && cat == needle) return true;
        return false;
      }).toList()
        ..sort((a, b) {
          if (a.pinToTop == b.pinToTop) return 0;
          return a.pinToTop ? -1 : 1;
        });

      filteredProducts = List<ProductModel>.from(_products);
      _productsState = CategoryProductsState.ready;
      _productsError = null;
      log("Found ${_products.length} products for subcategory $subcategory");
      notifyListeners();
    } catch (e, stackTrace) {
      if (generation != _loadGeneration ||
          _selectedCategory.trim() != subcategory) {
        return;
      }
      log("Error fetching subcategory products: $e");
      log("Stack trace: $stackTrace");
      _productsState = CategoryProductsState.error;
      _productsError = 'Could not load products';
      notifyListeners();
    }
  }

  Future<QuerySnapshot> _queryProductsForMainCategory(String mainCategory) async {
    // Admin products store the parent under `category` (not `main_category`).
    final byCategory = await FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: mainCategory)
        .get();
    if (byCategory.docs.isNotEmpty) return byCategory;

    try {
      final byMain = await FirebaseFirestore.instance
          .collection('products')
          .where('main_category', isEqualTo: mainCategory)
          .get();
      if (byMain.docs.isNotEmpty) return byMain;
    } catch (e) {
      log("Query by main_category failed: $e");
    }

    return byCategory;
  }

  Future<void> _fetchProductsForMainCategory(
    String mainCategory,
    int generation,
  ) async {
    try {
      final productSnapshot =
          await _queryProductsForMainCategory(mainCategory.trim());

      if (generation != _loadGeneration || _mainCategory != mainCategory) {
        return;
      }

      final parsed =
          await StartupIsolateParse.parseProductsFromUntypedSnapshot(
        productSnapshot,
        onlyAvailable: true,
      );

      if (generation != _loadGeneration || _mainCategory != mainCategory) {
        return;
      }

      _products = parsed
        ..sort((a, b) {
          if (a.pinToTop == b.pinToTop) return 0;
          return a.pinToTop ? -1 : 1;
        });

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

  static String _norm(String value) => value.trim().toLowerCase();

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
            CategoryModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
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
