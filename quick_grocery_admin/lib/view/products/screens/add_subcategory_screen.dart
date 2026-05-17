import 'package:quick_grocery_admin/model/catrgory_model.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSubCategoryScreen extends StatefulWidget {
  const AddSubCategoryScreen({super.key});

  @override
  State<AddSubCategoryScreen> createState() => _AddSubCategoryScreenState();
}

class _AddSubCategoryScreenState extends State<AddSubCategoryScreen> {
  List<CategoryModel>? mainCategories;
  String? selectedMainCategoryId;

  @override
  void initState() {
    super.initState();
    _loadMainCategories();
    Provider.of<ProductService>(context, listen: false).getAllSubCategories();
  }

  Future<void> _loadMainCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      setState(() {
        mainCategories = snapshot.docs.map((doc) {
          return CategoryModel.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductService>(context);
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppSpacing.h20,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WrapperWidget(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset('assets/icons/box.svg'),
                              AppSpacing.w10,
                              Text(
                                provider.editingSubCategoryId == null
                                    ? 'Add Subcategory'
                                    : 'Edit Subcategory',
                              ),
                            ],
                          ),
                          if (provider.editingSubCategoryId != null)
                            TextButton(
                              onPressed: () {
                                provider.cancelEdit();
                              },
                              child: Text('Cancel Edit'),
                            ),
                        ],
                      ),
                      AppSpacing.h20,
                      AdminResponsiveRow(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Select main category'),
                              AppSpacing.h10,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: provider
                                        .selectedMainCategoryForSubCategory,
                                    isExpanded: true,
                                    hint: const Text('Select main category'),
                                    onChanged: (v) => provider
                                        .onMainCategoryForSubCategoryChanged(v),
                                    items: mainCategories
                                        ?.map(
                                          (c) => DropdownMenuItem<String>(
                                            value: c.name,
                                            child: Text(c.name),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Subcategory name'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.subCategoryController,
                                hintText: 'Ex: Laptop',
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Subcategory order (index)'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.subCategoryOrderController,
                                hintText: 'Ex: 1',
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      AdminUploadSection(
                        label: 'Subcategory image',
                        buttonLabel: 'Upload image',
                        onTap: provider.pickImage,
                        preview: provider.imageBytes != null
                            ? Image.memory(
                                provider.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : provider.editingSubCategoryImage != null
                                ? Image.network(
                                    provider.editingSubCategoryImage!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                    ],
                  ),
                ),
                AppSpacing.h20,
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: AdminPrimaryButton(
                    label: 'Submit',
                    isLoading: provider.isLoading,
                    onPressed: () => provider.addSubCategory(context),
                  ),
                ),
                AppSpacing.h20,
                // Subcategories list table
                provider.allSubCategories == null
                    ? LinearProgressIndicator()
                    : WrapperWidget(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing:
                                MediaQuery.of(context).size.width * .14,
                            dataRowHeight: 70,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'SL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Main Category',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Subcategory Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Subcategory Order',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Action',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: List.generate(
                              provider.allSubCategories!.length,
                              (index) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(
                                      Text(
                                        provider
                                                .allSubCategories![index]
                                                .mainCategory ??
                                            'N/A',
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.black,
                                              ),
                                            ),
                                            child: Image.network(
                                              provider
                                                  .allSubCategories![index]
                                                  .image,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          AppSpacing.w10,
                                          Text(
                                            provider
                                                .allSubCategories![index]
                                                .name,
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        provider.allSubCategories![index].order,
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: AppColor.primary,
                                            ),
                                            onPressed: () {
                                              provider.initSubCategoryForEdit(
                                                provider.allSubCategories![index],
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              provider
                                                  .showDeleteSubCategoryDialog(
                                                    context,
                                                    provider
                                                        .allSubCategories![index]
                                                        .id,
                                                  );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
