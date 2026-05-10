import 'package:quick_grocery_admin/model/catrgory_model.dart';
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
            PrimaryAppBar(),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSpacing.h20,
                                Text('Select Main Category'),
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
                                          .selectedMainCategoryForSubCategory,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      iconSize: 24,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      hint: const Text("Select Main Category"),
                                      onChanged: (String? newValue) {
                                        provider
                                            .onMainCategoryForSubCategoryChanged(
                                              newValue,
                                            );
                                      },
                                      items: mainCategories
                                          ?.map<DropdownMenuItem<String>>((
                                            CategoryModel category,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: category.name,
                                              child: Text(category.name),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.w15,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text('Subcategory name'),
                              AppSpacing.h10,
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .24,
                                child: PrimaryTextField(
                                  controller: provider.subCategoryController,
                                  hintText: 'Ex: Laptop',
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.w15,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text(
                                'Subcategory order number ( based on index number)',
                              ),
                              AppSpacing.h10,
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .24,
                                child: PrimaryTextField(
                                  controller:
                                      provider.subCategoryOrderController,
                                  hintText: 'Ex: 1',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.h20,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subcategory Image'),
                              AppSpacing.h10,
                              Container(
                                height: MediaQuery.of(context).size.width * .08,
                                width: MediaQuery.of(context).size.width * .08,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Center(
                                  child: provider.imageBytes == null
                                      ? (provider.editingSubCategoryId != null &&
                                              provider.editingSubCategoryImage != null
                                          ? Image.network(
                                              provider.editingSubCategoryImage!,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              Icons.image,
                                              size: 40,
                                              color: Colors.grey.shade300,
                                            ))
                                      : Image.memory(provider.imageBytes!),
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
                        ],
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
                        onPressed: () => provider.addSubCategory(context),
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
