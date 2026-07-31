import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/vendor_model.dart';
import '../../services/product_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';
import '../../utils/product_search.dart';
import '../combo/combo_offers_screen.dart';
import '../reviews/vendor_reviews_screen.dart';
import 'add_edit_product_screen.dart';
import 'manage_categories_screen.dart';

/// Vendor inventory list with local, debounced product search.
///
/// Kept alive under [IndexedStack] so search query + scroll survive tab switches
/// and push/pop to product edit screens.
class ProductsScreen extends StatefulWidget {
  final VendorModel vendor;
  final Widget? bottomNavigationBar;

  const ProductsScreen({
    super.key,
    required this.vendor,
    this.bottomNavigationBar,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with AutomaticKeepAliveClientMixin {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _queryNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier<bool>(false);

  Timer? _debounce;
  List<ProductModel> _cachedAll = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onControllerTick);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onControllerTick);
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _queryNotifier.dispose();
    _hasTextNotifier.dispose();
    super.dispose();
  }

  void _onControllerTick() {
    final hasText = _searchController.text.isNotEmpty;
    if (_hasTextNotifier.value != hasText) {
      _hasTextNotifier.value = hasText;
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _queryNotifier.value = value.trim();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _queryNotifier.value = '';
    _hasTextNotifier.value = false;
    _searchFocus.unfocus();
    FocusScope.of(context).unfocus();
  }

  List<ProductModel> _filter(List<ProductModel> products, String query) {
    if (query.isEmpty) return products;
    return products
        .where(
          (p) => productMatchesSearchQuery(
            query,
            name: p.name,
            category: p.category,
            subcategory: p.subcategory ?? '',
            brand: p.brand,
            sku: p.sku,
            barcode: p.barcode,
            description: p.description,
            shopName: p.shopName,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _openProduct(ProductModel? product) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          vendor: widget.vendor,
          product: product,
        ),
      ),
    );
    // Stay on this State — query, results, and scroll are preserved.
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vendor = widget.vendor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
            },
            tooltip: 'Categories',
          ),
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VendorReviewsScreen(vendorId: vendor.id),
                ),
              );
            },
            tooltip: 'Reviews',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_basket_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VendorComboOffersScreen(vendor: vendor),
                ),
              );
            },
            tooltip: 'Combo offers',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openProduct(null),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ValueListenableBuilder<bool>(
              valueListenable: _hasTextNotifier,
              builder: (context, hasText, _) {
                return TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: false,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchFocus.unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[700],
                    ),
                    suffixIcon: hasText
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _clearSearch,
                            tooltip: 'Clear search',
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColor.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getVendorProducts(vendor.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedAll.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError && _cachedAll.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        AppSpacing.h20,
                        Text(
                          'Error loading products',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        AppSpacing.h10,
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasData) {
                  _cachedAll = snapshot.data ?? const [];
                }
                final all = _cachedAll;

                if (all.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        AppSpacing.h20,
                        Text(
                          'No products yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AppSpacing.h10,
                        Text(
                          'Tap the + button to add your first product',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ValueListenableBuilder<String>(
                  valueListenable: _queryNotifier,
                  builder: (context, query, _) {
                    final products = _filter(all, query);

                    if (products.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              AppSpacing.h20,
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              AppSpacing.h10,
                              Text(
                                'Try searching with another keyword.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ProductCard(
                          product: product,
                          vendor: vendor,
                          highlightQuery: query,
                          onTap: () => _openProduct(product),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VendorModel vendor;
  final String highlightQuery;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.vendor,
    required this.highlightQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    const nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final highlightStyle = nameStyle.copyWith(
      color: AppColor.primary,
      backgroundColor: AppColor.primary.withValues(alpha: 0.18),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              AppSpacing.w15,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: splitHighlightedSegments(
                          product.name,
                          highlightQuery,
                        )
                            .map(
                              (seg) => TextSpan(
                                text: seg.text,
                                style: seg.highlight
                                    ? highlightStyle
                                    : nameStyle,
                              ),
                            )
                            .toList(growable: false),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.h5,
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (product.sku.isNotEmpty || product.brand.isNotEmpty) ...[
                      AppSpacing.h5,
                      Text(
                        [
                          if (product.brand.isNotEmpty) product.brand,
                          if (product.sku.isNotEmpty) 'SKU: ${product.sku}',
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    AppSpacing.h5,
                    Row(
                      children: [
                        Text(
                          '₹${product.price}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                        if (product.slashedPrice.isNotEmpty &&
                            product.slashedPrice != product.price)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '₹${product.slashedPrice}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                      ],
                    ),
                    AppSpacing.h5,
                    Row(
                      children: [
                        if (product.isOutOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isActive ? 'In Stock' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: product.isActive
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        AppSpacing.w10,
                        Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'toggle') {
                    try {
                      await productService.toggleProductStatus(
                        product.id,
                        !product.isActive,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              product.isActive
                                  ? 'Product deactivated'
                                  : 'Product activated',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not update status: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Product?'),
                        content: const Text(
                          'This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await productService.softDeleteProduct(product.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          product.isActive
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        AppSpacing.w10,
                        Text(product.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
