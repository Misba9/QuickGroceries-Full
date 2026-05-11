import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/catrgory_model.dart';
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
    Provider.of<ProductService>(context, listen: false).fetchVendors();
    Provider.of<ProductService>(context, listen: false).fetchCategory();
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
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () {},
                                  ),
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
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      onPressed: () {},
                                    ),
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
                        Consumer<ProductService>(
                          builder: (context, p, _) {
                            if (p.filteredProductsList == null) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: p.filteredProductsList!.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final product = p.filteredProductsList![i];
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
                            );
                          },
                        ),
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
    return FutureBuilder<List<CategoryModel>?>(
      future: provider.fetchCategory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No items found.'));
        }
        final items = snapshot.data!;
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
      },
    );
  }
}

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
