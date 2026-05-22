import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/model/catrgory_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ProductAddScreen extends StatefulWidget {
  const ProductAddScreen({super.key});

  @override
  State<ProductAddScreen> createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ProductService>(context, listen: false).fetchCategory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductService>(context);
    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Products', style: AppTextStyles.heading),
          const SizedBox(height: 20),
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
                      // Subcategory selection (only shown if category is selected and has subcategories)
                      if (provider.selectedItem != null && provider.subCategories != null && provider.subCategories!.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSpacing.h10,
                                  Text('Select Subcategory (Optional)'),
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
                                      child: DropdownButton<String?>(
                                        value: provider.selectedSubCategory,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        iconSize: 24,
                                        isExpanded: true,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        hint: const Text("Select Subcategory (Optional)"),
                                        onChanged: (String? newValue) {
                                          provider.onSubCategoryChanged(newValue);
                                        },
                                        items: [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('None'),
                                          ),
                                          ...provider.subCategories!.map<DropdownMenuItem<String?>>((
                                            category,
                                          ) {
                                            return DropdownMenuItem<String?>(
                                              value: category.name,
                                              child: Text(category.name),
                                            );
                                          }),
                                        ],
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
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSpacing.h20,
                                Text('HSN Code (If applicable)'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: PrimaryTextField(
                                    controller: provider.hsnsCode,
                                    hintText: 'Ex: 06723627',
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
                                Text('CGST (If applicable)'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: PrimaryTextField(
                                    controller: provider.cGstcontroller,
                                    hintText: 'Ex: 2.5 (no need to add %)',
                                  ),
                                ),
                              ],
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
                                Text('Cess (If applicable)'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: PrimaryTextField(
                                    controller: provider.ceesGSt,
                                    hintText: 'Ex: 0.7 (no need to add %)',
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
                                Text('S/UT GST (If applicable)'),
                                AppSpacing.h10,
                                SizedBox(
                                  child: PrimaryTextField(
                                    controller: provider.cutcontroller,
                                    hintText: 'Ex: 2.5 (no need to add %)',
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
                      AdminUploadSection(
                        label: 'Product image (main)',
                        buttonLabel: 'Upload main image',
                        onTap: provider.pickImage,
                        preview: provider.imageBytes == null
                            ? null
                            : Image.memory(
                                provider.imageBytes!,
                                fit: BoxFit.cover,
                              ),
                      ),
                      AppSpacing.h20,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Additional Images'),
                          AppSpacing.h10,
                          if (provider.imageBytesList.isNotEmpty)
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(
                                provider.imageBytesList.length,
                                (index) => Stack(
                                  children: [
                                    Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          provider.imageBytesList[index],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: GestureDetector(
                                        onTap: () {
                                          provider.removeImage(index);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          AppSpacing.h10,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: provider.pickMultipleImages,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Add images'),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Product Videos'),
                          AppSpacing.h10,
                          if (provider.videoBytesList.isNotEmpty)
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(
                                provider.videoBytesList.length,
                                (index) => Stack(
                                  children: [
                                    Container(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        color: Colors.black87,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.play_circle_filled,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: GestureDetector(
                                        onTap: () {
                                          provider.removeVideo(index);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 5,
                                      left: 5,
                                      right: 5,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Video ${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          AppSpacing.h10,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: provider.pickVideo,
                              icon: const Icon(Icons.video_library),
                              label: const Text('Add video'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(15),
                    child: AdminPrimaryButton(
                      label: 'Submit',
                      isLoading: provider.isLoading,
                      onPressed: () => provider.addProduct(context),
                    ),
                  ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
