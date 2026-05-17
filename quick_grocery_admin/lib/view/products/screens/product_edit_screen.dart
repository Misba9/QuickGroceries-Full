import 'package:quick_grocery_admin/model/catrgory_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/add_rating_screen.dart';
import 'package:quick_grocery_admin/view/products/widgets/admin_product_settings_panel.dart';
import 'package:quick_grocery_admin/view/products/widgets/product_quality_panel.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:quick_grocery_admin/view/products/services/rating_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({super.key, required this.product});
  final ProductModel product;

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  @override
  void initState() {
    Provider.of<ProductService>(context, listen: false).fetchCategory();
    Provider.of<ProductService>(
      context,
      listen: false,
    ).initProduct(widget.product);
    Provider.of<ProductService>(context, listen: false).fetchVendors();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductService>(context);
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Column(
        children: [
          PrimaryAppBar(isBackButton: true),
          AppSpacing.h20,
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                WrapperWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset('assets/icons/box.svg'),
                          AppSpacing.w10,
                          Text('Add Product'),
                        ],
                      ),
                      AppSpacing.h20,
                      AdminResponsiveRow(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Product name'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.productNamecontroller,
                                hintText: 'Ex: engi oil',
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Product MRP'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.mrpcontroller,
                                hintText: 'Ex: 120.00',
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Price (Selling price)'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.pricecontroller,
                                hintText: 'Ex: 110.00',
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Select Category'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: FutureBuilder<List<CategoryModel>?>(
                                    future: provider.fetchCategory(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                          ),
                                        );
                                      } else if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return const Center(
                                          child: Text('No items found.'),
                                        );
                                      } else {
                                        final items = snapshot.data!;

                                        return DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            hintText: 'Select product category',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    8,
                                                  ), // Optional: Rounded corners
                                              borderSide: BorderSide(
                                                color:
                                                    Colors.grey, // Border color
                                                width:
                                                    0.5, // Reduced border thickness
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey,
                                                width:
                                                    0.5, // Border thickness when not focused
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: AppColor.primary,
                                                width: 0.8,
                                              ),
                                            ),
                                          ),
                                          value: provider.selectedItem,
                                          items: items.map((item) {
                                            return DropdownMenuItem<String>(
                                              value: item.name,
                                              child: Text(item.name),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            provider.onCategoryChanged(value!);
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.w10,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Select Unit'),
                                AppSpacing.h10,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: provider
                                          .selectedunit, // Use selectedunit here
                                      icon: const Icon(Icons.arrow_drop_down),
                                      iconSize: 24,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      hint: const Text("Select Unit"),
                                      onChanged: (String? newValue) {
                                        provider.onUnitChanged(newValue!);
                                      },
                                      items: provider.unit
                                          .map<DropdownMenuItem<String>>((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h10,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSpacing.h10,
                          Text('Description (EN)'),
                          AppSpacing.h10,
                          TextFormField(
                            controller: provider.descriptioncontroller,
                            maxLines: 4,
                            autofocus: false,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ), // Optional: Rounded corners
                                borderSide: BorderSide(
                                  color: Colors.grey, // Border color
                                  width: 0.5, // Reduced border thickness
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width:
                                      0.5, // Border thickness when not focused
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColor.primary,
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h10,
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSpacing.h20,
                                Text(
                                  'Enter product unit per item (eg: 500g for 1 Qty)',
                                ),
                                AppSpacing.h10,
                                SizedBox(
                                  child: PrimaryTextField(
                                    controller: provider.unitcontroller,
                                    hintText: 'Ex: 1',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.w10,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSpacing.h20,
                                Text('Enter product stock'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: PrimaryTextField(
                                    controller: provider.stockcontroller,
                                    hintText: 'Ex: 10',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h10,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSpacing.h20,
                                Text('Enter minimum order quantity'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: PrimaryTextField(
                                    controller: provider.quantitycontroller,
                                    hintText: 'Ex: 5',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.w10,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Select Vendor'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: FutureBuilder<List<VendorModel>?>(
                                    future: provider.fetchVendors(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                          ),
                                        );
                                      } else if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return const Center(
                                          child: Text('No items found.'),
                                        );
                                      } else {
                                        final items = snapshot.data!;

                                        return DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            hintText: 'Select Vendor',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    8,
                                                  ), // Optional: Rounded corners
                                              borderSide: BorderSide(
                                                color:
                                                    Colors.grey, // Border color
                                                width:
                                                    0.5, // Reduced border thickness
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey,
                                                width:
                                                    0.5, // Border thickness when not focused
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: AppColor.primary,
                                                width: 0.8,
                                              ),
                                            ),
                                          ),
                                          value: provider.selectedVendor,
                                          items: items.map((item) {
                                            return DropdownMenuItem<String>(
                                              value: item.shopName,
                                              child: Text(item.shopName),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            provider.onVendorChanged(value!);
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h10,
                      AdminResponsiveRow(
                        breakpoint: 640,
                        children: [
                          AdminUploadSection(
                            label: 'Product image',
                            buttonLabel: 'Upload image',
                            onTap: provider.pickImage,
                            preview: provider.imageBytes != null
                                ? Image.memory(
                                    provider.imageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : provider.selectedImage.isNotEmpty
                                    ? Image.network(
                                        provider.selectedImage,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Today\'s best deal'),
                              AppSpacing.h10,
                              Switch(
                                value: provider.isTodaysBest,
                                onChanged: provider.onTodaysBest,
                              ),
                              AppSpacing.h20,
                              const Text('Most selling product'),
                              AppSpacing.h10,
                              Switch(
                                value: provider.isMostSelling,
                                onChanged: provider.onMostSellingChange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.h20,
                WrapperWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColor.primary),
                          AppSpacing.w10,
                          Text(
                            'Product Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      AdminPrimaryButton(
                        label: 'Add product rating',
                        icon: Icons.add,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider(
                                create: (_) => RatingService(),
                                child: AddRatingScreen(
                                  product: widget.product,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                AppSpacing.h20,
                AdminProductSettingsPanel(productId: widget.product.id),
                AppSpacing.h20,
                ProductQualityPanel(productId: widget.product.id),
                AppSpacing.h20,
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: AdminPrimaryButton(
                    label: 'Update product',
                    isLoading: provider.isLoading,
                    onPressed: () =>
                        provider.updateProduct(context, widget.product.id),
                  ),
                ),
                AppSpacing.h20,
                AppSpacing.h20,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
