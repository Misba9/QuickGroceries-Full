import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/model/catrgory_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';

/// Add / edit subcategories — scroll via [AdminPageSlot].
class AddSubCategoryScreen extends StatefulWidget {
  const AddSubCategoryScreen({super.key});

  @override
  State<AddSubCategoryScreen> createState() => _AddSubCategoryScreenState();
}

class _AddSubCategoryScreenState extends State<AddSubCategoryScreen> {
  List<CategoryModel>? mainCategories;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMainCategories();
      context.read<ProductService>().getAllSubCategories();
    });
  }

  Future<void> _loadMainCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      if (!mounted) return;
      setState(() {
        mainCategories = snapshot.docs
            .map(
              (doc) => CategoryModel.fromFirestore(
                doc.data(),
                doc.id,
              ),
            )
            .toList();
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        mainCategories = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductService>();

    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.editingSubCategoryId == null
                ? 'Add Subcategory'
                : 'Edit Subcategory',
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 20),
          WrapperWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/box.svg'),
                    AppSpacing.w10,
                    Expanded(
                      child: Text(
                        'Subcategory details',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (provider.editingSubCategoryId != null)
                      TextButton(
                        onPressed: provider.cancelEdit,
                        child: const Text('Cancel edit'),
                      ),
                  ],
                ),
                AppSpacing.h20,
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Could not load categories: $_loadError',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, c) {
                    final stacked = c.maxWidth < 720;
                    final dropdown = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Select main category'),
                        AppSpacing.h10,
                        SizedBox(
                          height: 52,
                          child: mainCategories == null
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Container(
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
                                      onChanged: mainCategories!.isEmpty
                                          ? null
                                          : (v) => provider
                                              .onMainCategoryForSubCategoryChanged(
                                                v,
                                              ),
                                      items: mainCategories!
                                          .map(
                                            (cat) => DropdownMenuItem<String>(
                                              value: cat.name,
                                              child: Text(cat.name),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                    final formFields = [
                      dropdown,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Subcategory order (index)'),
                          AppSpacing.h10,
                          PrimaryTextField(
                            controller: provider.subCategoryOrderController,
                            hintText: 'Ex: 1',
                          ),
                        ],
                      ),
                    ];
                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < formFields.length; i++) ...[
                            if (i > 0) AppSpacing.h20,
                            formFields[i],
                          ],
                        ],
                      );
                    }
                    final gap = 16.0;
                    final colW = (c.maxWidth - gap * 2) / 3;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: colW, child: formFields[0]),
                        SizedBox(width: gap),
                        SizedBox(width: colW, child: formFields[1]),
                        SizedBox(width: gap),
                        SizedBox(width: colW, child: formFields[2]),
                      ],
                    );
                  },
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
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            )
                          : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AdminPrimaryButton(
            label: 'Submit',
            isLoading: provider.isLoading,
            onPressed: () => provider.addSubCategory(context),
          ),
          const SizedBox(height: 24),
          _SubCategoryTable(provider: provider),
        ],
      ),
    );
  }
}

class _SubCategoryTable extends StatelessWidget {
  const _SubCategoryTable({required this.provider});

  final ProductService provider;

  @override
  Widget build(BuildContext context) {
    if (provider.allSubCategories == null) {
      return const AdminBoundedCenter(
        minHeight: 120,
        child: CircularProgressIndicator(),
      );
    }
    if (provider.allSubCategories!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No subcategories yet. Add one above.'),
      );
    }

    return WrapperWidget(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          columns: const [
            DataColumn(
              label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)),
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
              label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: List.generate(provider.allSubCategories!.length, (index) {
            final sub = provider.allSubCategories![index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(sub.mainCategory ?? 'N/A')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          sub.image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      AppSpacing.w10,
                      Text(sub.name),
                    ],
                  ),
                ),
                DataCell(Text(sub.order)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColor.primary),
                        onPressed: () => provider.initSubCategoryForEdit(sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => provider.showDeleteSubCategoryDialog(
                          context,
                          sub.id,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
