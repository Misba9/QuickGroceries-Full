import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
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
                      AdminResponsiveRow(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Category name'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.categoryController,
                                hintText: 'Ex: HP',
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Category order number (based on index)',
                              ),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.categoryOrderController,
                                hintText: 'Ex: 6',
                              ),
                            ],
                          ),
                          AdminUploadSection(
                            label: 'Category image',
                            buttonLabel: 'Upload image',
                            onTap: () => provider.pickImage(),
                            preview: provider.imageBytes == null
                                ? (provider.editingCategoryImage != null
                                    ? Image.network(
                                        provider.editingCategoryImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : null)
                                : Image.memory(
                                    provider.imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ],
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
                    onPressed: () => provider.addCategory(context),
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
