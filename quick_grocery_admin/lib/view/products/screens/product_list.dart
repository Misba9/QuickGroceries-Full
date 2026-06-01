import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/home/screens/home_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/product_edit_screen.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? selectedValue;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final svc = Provider.of<ProductService>(context, listen: false);
    svc.ensureProductsListener();
    svc.ensureCategoriesListener();
    svc.ensureVendorsListener();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductService>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final pad = adminResponsivePadding(w);
        final narrow = adminIsMobileWidth(w);

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product List',
                    style: TextStyle(
                      fontSize: adminResponsiveFontSize(
                        w,
                        mobile: 17,
                        tablet: 18,
                        desktop: 20,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.h10,
                  AdminLiveSyncBar(
                    state: provider.productsSyncState,
                    label: 'Products',
                  ),
                  AppSpacing.h10,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (narrow)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Category'),
                              AppSpacing.h10,
                              _categoryDropdown(provider),
                              AppSpacing.h10,
                              TextField(
                                autofocus: false,
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onChanged: provider.onSearchQuary,
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Category'),
                                    AppSpacing.h10,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _categoryDropdown(provider),
                                        ),
                                        if (provider.selectedItem != null)
                                          IconButton(
                                            onPressed: provider.clear,
                                            icon: const Icon(Icons.close),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.w20,
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  autofocus: false,
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: provider.onSearchQuary,
                                ),
                              ),
                            ],
                          ),
                        AppSpacing.h20,
                        _ProductListBody(narrow: narrow),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryDropdown(ProductService provider) {
    if (provider.categoriesSyncState.hasError) {
      return Text(
        provider.categoriesSyncState.errorMessage ?? 'Could not load categories',
        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
      );
    }
    if (provider.category == null && provider.categoriesSyncState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final items = provider.category ?? [];
    if (items.isEmpty) {
      return const Text('No categories yet.');
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Select product category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.primary, width: 0.8),
        ),
      ),
      value: provider.selectedItem,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.name,
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) provider.onCategoryQuaryChange(value);
      },
    );
  }
}

class _ProductListBody extends StatelessWidget {
  const _ProductListBody({required this.narrow});

  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductService>(
      builder: (context, p, _) {
        if (p.productsSyncState.hasError) {
          return _ProductListMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load products',
            subtitle: p.productsSyncState.errorMessage ?? 'Unknown error',
            action: FilledButton(
              onPressed: p.ensureProductsListener,
              child: const Text('Retry'),
            ),
          );
        }
        if (p.filteredProductsList == null && p.productsSyncState.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final page = p.pagedFilteredProducts;
        if (page.isEmpty) {
          return _ProductListMessage(
            icon: Icons.inventory_2_outlined,
            title: 'No products',
            subtitle: p.productsList?.isEmpty ?? true
                ? 'Add a product from Admin or Vendor app — it will appear here live.'
                : 'No products match your filters.',
          );
        }
        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: page.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final product = page[i];
                return _ProductRowCard(
                  narrow: narrow,
                  product: product,
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductEditScreen(
                          product: product,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (p.hasMoreProducts) ...[
              AppSpacing.h15,
              OutlinedButton(
                onPressed: p.loadMoreProducts,
                child: Text(
                  'Load more (${p.filteredProductsList!.length - page.length} remaining)',
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProductListMessage extends StatelessWidget {
  const _ProductListMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          AppSpacing.h10,
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          AppSpacing.h10,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          if (action != null) ...[AppSpacing.h15, action!],
        ],
      ),
    );
  }
}

Widget _statusChip(String label, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

class _ProductRowCard extends StatelessWidget {
  const _ProductRowCard({
    required this.narrow,
    required this.product,
    required this.onEdit,
  });

  final bool narrow;
  final ProductModel product;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: narrow ? double.infinity : 140,
        height: narrow ? 180 : 140,
        child: Image.network(
          product.image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported),
          ),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        AppSpacing.h10,
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (product.isDeleted)
              _statusChip('Deleted', Colors.black87, Colors.grey.shade300)
            else if (product.isActive)
              _statusChip('Active', Colors.green.shade800, Colors.green.shade50)
            else
              _statusChip('Inactive', Colors.red.shade800, Colors.red.shade50),
          ],
        ),
        AppSpacing.h10,
        NamedFieldWidget(label: 'Brand', value: product.category),
        NamedFieldWidget(label: 'Vendor Name', value: product.shopName),
        NamedFieldWidget(label: 'Price', value: product.price.toString()),
        NamedFieldWidget(label: 'Stock', value: product.stock.toString()),
        NamedFieldWidget(label: 'ID', value: product.id.toString()),
        NamedFieldWidget(label: 'MAX Order', value: product.maxOrder.toString()),
        Text(
          product.description.toString(),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                img,
                AppSpacing.h10,
                details,
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, color: AppColor.primary),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                img,
                AppSpacing.w20,
                Expanded(child: details),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, color: AppColor.primary),
                ),
              ],
            ),
    );
  }
}
