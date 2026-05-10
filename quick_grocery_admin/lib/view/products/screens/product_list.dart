import 'package:quick_grocery_admin/model/catrgory_model.dart';
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
  List<String> items = ['Apple', 'Banana', 'Orange', 'Mango'];
  String? selectedValue;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    Provider.of<ProductService>(context, listen: false).fetchVendors();
    Provider.of<ProductService>(context, listen: false).fetchCategory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductService>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.h20,
          AppSpacing.h20,
          Text(
            'Product List',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          AppSpacing.h10,
          Container(
            padding: EdgeInsets.all(15),
            width: MediaQuery.of(context).size.width * .80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category'),
                        AppSpacing.h10,
                        Row(
                          children: [
                            SizedBox(
                              width:
                                  300, // Adjust width for better web experience
                              child: FutureBuilder<List<CategoryModel>?>(
                                future: provider.fetchCategory(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ), // Optional: Rounded corners
                                          borderSide: BorderSide(
                                            color: Colors.grey, // Border color
                                            width:
                                                0.5, // Reduced border thickness
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                            width:
                                                0.5, // Border thickness when not focused
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                        provider.onCategoryQuaryChange(value!);
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                            Visibility(
                              visible: provider.selectedItem != null,
                              child: IconButton(
                                onPressed: () {
                                  provider.clear();
                                },
                                icon: Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 400,
                      child: TextField(
                        autofocus: false,
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.arrow_forward,
                            ), // Search button icon
                            onPressed: () {
                              print('Searching for: ${searchController.text}');
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          provider.onSearchQuary(value);
                        },
                      ),
                    ),
                  ],
                ),
                AppSpacing.h20,
                Consumer<ProductService>(
                  builder: (context, p, _) {
                    return p.filteredProductsList == null
                        ? CircularProgressIndicator()
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: p.filteredProductsList!.length,
                            itemBuilder: (context, i) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 10),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                width: MediaQuery.of(context).size.width * .80,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 200,
                                      width: 200,
                                      child: Image.network(
                                        p.filteredProductsList![i].image,
                                      ),
                                    ),
                                    AppSpacing.w20,
                                    Row(
                                      children: [
                                        SizedBox(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              .58,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.filteredProductsList![i].name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              AppSpacing.h10,
                                              NamedFieldWidget(
                                                label: 'Brand',
                                                value: p
                                                    .filteredProductsList![i]
                                                    .category,
                                              ),
                                              NamedFieldWidget(
                                                label: 'Vendor Name',
                                                value: p
                                                    .filteredProductsList![i]
                                                    .shopName,
                                              ),
                                              NamedFieldWidget(
                                                label: 'Price',
                                                value: p
                                                    .filteredProductsList![i]
                                                    .price
                                                    .toString(),
                                              ),
                                              NamedFieldWidget(
                                                label: 'Stock',
                                                value: p
                                                    .filteredProductsList![i]
                                                    .stock
                                                    .toString(),
                                              ),
                                              NamedFieldWidget(
                                                label: 'ID',
                                                value: p
                                                    .filteredProductsList![i]
                                                    .id
                                                    .toString(),
                                              ),
                                              NamedFieldWidget(
                                                label: 'MAX Order',
                                                value: p
                                                    .filteredProductsList![i]
                                                    .maxOrder
                                                    .toString(),
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Description :'),
                                                  AppSpacing.w10,
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width *
                                                        .50,
                                                    child: Text(
                                                      p
                                                          .filteredProductsList![i]
                                                          .description
                                                          .toString(),
                                                      maxLines: 2,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductEditScreen(
                                                  product: p
                                                      .filteredProductsList![i],
                                                ),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }
}
