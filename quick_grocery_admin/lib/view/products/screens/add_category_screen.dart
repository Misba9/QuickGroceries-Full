import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';

/// Add / edit categories — scroll via [AdminPageSlot].
class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductService>().getCategories();
      }
    });
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
            provider.editingCategoryId == null ? 'Add Category' : 'Edit Category',
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
                        'Category details',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (provider.editingCategoryId != null)
                      TextButton(
                        onPressed: provider.cancelEdit,
                        child: const Text('Cancel edit'),
                      ),
                  ],
                ),
                AppSpacing.h20,
                LayoutBuilder(
                  builder: (context, c) {
                    final stacked = c.maxWidth < 720;
                    final formFields = [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Category name'),
                          AppSpacing.h10,
                          PrimaryTextField(
                            controller: provider.categoryController,
                            hintText: 'Ex: Groceries',
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Category order number (based on index)'),
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
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image_outlined),
                                  )
                                : null)
                            : Image.memory(
                                provider.imageBytes!,
                                fit: BoxFit.cover,
                              ),
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
              ],
            ),
          ),
          const SizedBox(height: 20),
          AdminPrimaryButton(
            label: 'Submit',
            isLoading: provider.isLoading,
            onPressed: () => provider.addCategory(context),
          ),
          const SizedBox(height: 24),
          _CategoryTable(provider: provider),
        ],
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({required this.provider});

  final ProductService provider;

  @override
  Widget build(BuildContext context) {
    if (provider.categories == null) {
      return const AdminBoundedCenter(
        minHeight: 120,
        child: CircularProgressIndicator(),
      );
    }
    if (provider.categories!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No categories yet. Add one above.'),
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
              label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: List.generate(provider.categories!.length, (index) {
            final cat = provider.categories![index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          cat.image,
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
                      Text(cat.name),
                    ],
                  ),
                ),
                DataCell(Text(cat.order)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColor.primary),
                        onPressed: () => provider.initCategoryForEdit(cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            provider.showDeleteDialog(context, cat.id),
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
