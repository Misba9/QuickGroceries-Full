import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  @override
  void initState() {
    Provider.of<ProductService>(context, listen: false).getCategories();
    super.initState();
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
                                provider.editingCategoryId == null
                                    ? 'Add Category'
                                    : 'Edit Category',
                              ),
                            ],
                          ),
                          if (provider.editingCategoryId != null)
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text('Category name'),
                              AppSpacing.h10,
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .24,
                                child: PrimaryTextField(
                                  controller: provider.categoryController,
                                  hintText: 'Ex: HP',
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
                                'Category order number ( based on index number)',
                              ),
                              AppSpacing.h10,
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .24,
                                child: PrimaryTextField(
                                  controller: provider.categoryOrderController,
                                  hintText: 'Ex: 6',
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.w15,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.h20,
                              Text('Category Image'),
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
                                      ? (provider.editingCategoryId != null &&
                                              provider.editingCategoryImage != null
                                          ? Image.network(
                                              provider.editingCategoryImage!,
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
                        onPressed: () => provider.addCategory(context),
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

                // Wrap the DataTable with SingleChildScrollView for proper scrolling
                provider.categories == null
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
                                  'Category Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Category Order',
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
                            rows: List.generate(provider.categories!.length, (
                              index,
                            ) {
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString())),
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
                                            provider.categories![index].image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        AppSpacing.w10,
                                        Text(provider.categories![index].name),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(provider.categories![index].order),
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
                                            provider.initCategoryForEdit(
                                              provider.categories![index],
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            provider.showDeleteDialog(
                                              context,
                                              provider.categories![index].id,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
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
