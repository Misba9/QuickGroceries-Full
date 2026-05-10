import 'package:quick_grocery_admin/model/catrgory_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/add_rating_screen.dart';
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
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text('Product name'),
                              AppSpacing.h10,
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .24,
                                child: PrimaryTextField(
                                  controller: provider.productNamecontroller,
                                  hintText: 'Ex: engi oil',
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.w15,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text('Product MRP'),
                              AppSpacing.h10,
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .24,
                                child: PrimaryTextField(
                                  controller: provider.mrpcontroller,
                                  hintText: 'Ex: 120.00',
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.w15,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text('Price (Selling price)'),
                              AppSpacing.h10,
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .24,
                                child: PrimaryTextField(
                                  controller: provider.pricecontroller,
                                  hintText: 'Ex: 110.00',
                                ),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text('Product Image'),
                              AppSpacing.h10,
                              provider.selectedImage == ''
                                  ? Container(
                                      height:
                                          MediaQuery.of(context).size.width *
                                          .15,
                                      width:
                                          MediaQuery.of(context).size.width *
                                          .15,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Center(
                                        child: provider.imageBytes == null
                                            ? Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey.shade300,
                                              )
                                            : Image.memory(
                                                provider.imageBytes!,
                                              ),
                                      ),
                                    )
                                  : Container(
                                      height:
                                          MediaQuery.of(context).size.width *
                                          .15,
                                      width:
                                          MediaQuery.of(context).size.width *
                                          .15,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Center(
                                        child: Image.network(
                                          provider.selectedImage,
                                        ),
                                      ),
                                    ),
                              AppSpacing.h20,
                              GestureDetector(
                                onTap: () {
                                  provider.pickImage();
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * .12,
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add),
                                      AppSpacing.w10,
                                      Text('Upload Image'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.w20,
                          AppSpacing.w20,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              AppSpacing.h20,
                              Text('Todays Best Deal'),
                              AppSpacing.h10,
                              Switch(
                                value: provider.isTodaysBest,
                                onChanged: (v) => provider.onTodaysBest(v),
                              ),
                              AppSpacing.h20,
                              AppSpacing.h20,
                              AppSpacing.h20,
                              Text('Most Selling Product'),
                              AppSpacing.h10,
                              Switch(
                                value: provider.isMostSelling,
                                onChanged: (v) =>
                                    provider.onMostSellingChange(v),
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
                      SizedBox(
                        height: 40,
                        width: 300,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColor.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                          icon: Icon(Icons.add),
                          label: Text('Product Rating Add'),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h20,
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SizedBox(
                      height: 40,
                      width: 300,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColor.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            provider.updateProduct(context, widget.product.id),
                        child: provider.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 1,
                                ),
                              )
                            : Text('Submit'),
                      ),
                    ),
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
