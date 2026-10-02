import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/vendor_form_fields.dart';

/// Vendor screen to add / edit categories and subcategories.
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Subcategories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _CategoriesTab(),
          _SubcategoriesTab(),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  final _service = CategoryService();
  final _nameController = TextEditingController();
  final _orderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _editingId;
  String? _existingImage;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _orderController.clear();
    _editingId = null;
    _existingImage = null;
    _imageBytes = null;
    setState(() {});
  }

  void _startEdit(CategoryModel cat) {
    _editingId = cat.id;
    _nameController.text = cat.name;
    _orderController.text = cat.order.toString();
    _existingImage = cat.image;
    _imageBytes = null;
    setState(() {});
  }

  Future<void> _pickImage() async {
    final bytes = await _service.pickImageBytes();
    if (bytes != null && mounted) {
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final order = int.tryParse(_orderController.text.trim());
    if (order == null) {
      _snack('Enter a valid order number');
      return;
    }

    if (_editingId == null && _imageBytes == null) {
      _snack('Please upload a category image');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_editingId == null) {
        await _service.addCategory(
          name: _nameController.text,
          order: order,
          imageBytes: _imageBytes!,
        );
        _snack('Category added');
      } else {
        await _service.updateCategory(
          id: _editingId!,
          name: _nameController.text,
          order: order,
          imageBytes: _imageBytes,
          existingImage: _existingImage,
        );
        _snack('Category updated');
      }
      _resetForm();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(CategoryModel cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${cat.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteCategory(cat.id);
      if (_editingId == cat.id) _resetForm();
      _snack('Category deleted');
    } catch (e) {
      _snack('$e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<CategoryModel>>(
            stream: _service.getCategoriesStream(),
            builder: (context, snapshot) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CategoryFormCard(
                    formKey: _formKey,
                    title: _editingId == null
                        ? 'Add category'
                        : 'Edit category',
                    nameController: _nameController,
                    orderController: _orderController,
                    imageBytes: _imageBytes,
                    existingImage: _existingImage,
                    saving: _saving,
                    isEditing: _editingId != null,
                    onPickImage: _pickImage,
                    onCancelEdit: _editingId != null ? _resetForm : null,
                    onSave: _save,
                  ),
                  AppSpacing.h20,
                  Text(
                    'All categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  AppSpacing.h10,
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if ((snapshot.data ?? const []).isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No categories yet. Add one above.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...snapshot.data!.map(
                      (cat) => _CategoryListTile(
                        category: cat,
                        onEdit: () => _startEdit(cat),
                        onDelete: () => _confirmDelete(cat),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubcategoriesTab extends StatefulWidget {
  const _SubcategoriesTab();

  @override
  State<_SubcategoriesTab> createState() => _SubcategoriesTabState();
}

class _SubcategoriesTabState extends State<_SubcategoriesTab> {
  final _service = CategoryService();
  final _nameController = TextEditingController();
  final _orderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedMainCategory;
  String? _editingId;
  String? _existingImage;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _orderController.clear();
    _selectedMainCategory = null;
    _editingId = null;
    _existingImage = null;
    _imageBytes = null;
    setState(() {});
  }

  void _startEdit(CategoryModel sub) {
    _editingId = sub.id;
    _nameController.text = sub.name;
    _orderController.text = sub.order.toString();
    _selectedMainCategory = sub.mainCategory;
    _existingImage = sub.image;
    _imageBytes = null;
    setState(() {});
  }

  Future<void> _pickImage() async {
    final bytes = await _service.pickImageBytes();
    if (bytes != null && mounted) {
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final order = int.tryParse(_orderController.text.trim());
    if (order == null) {
      _snack('Enter a valid order number');
      return;
    }
    if (_selectedMainCategory == null || _selectedMainCategory!.isEmpty) {
      _snack('Please select a main category');
      return;
    }
    if (_editingId == null && _imageBytes == null) {
      _snack('Please upload a subcategory image');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_editingId == null) {
        await _service.addSubCategory(
          name: _nameController.text,
          order: order,
          mainCategoryName: _selectedMainCategory!,
          imageBytes: _imageBytes!,
        );
        _snack('Subcategory added');
      } else {
        await _service.updateSubCategory(
          id: _editingId!,
          name: _nameController.text,
          order: order,
          mainCategoryName: _selectedMainCategory!,
          imageBytes: _imageBytes,
          existingImage: _existingImage,
        );
        _snack('Subcategory updated');
      }
      _resetForm();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(CategoryModel sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subcategory?'),
        content: Text('Delete "${sub.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteSubCategory(sub.id);
      if (_editingId == sub.id) _resetForm();
      _snack('Subcategory deleted');
    } catch (e) {
      _snack('$e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryModel>>(
      stream: _service.getCategoriesStream(),
      builder: (context, mainSnap) {
        final mainCategories = mainSnap.data ?? const <CategoryModel>[];
        final loadingMains = mainSnap.connectionState ==
                ConnectionState.waiting &&
            !mainSnap.hasData;

        return StreamBuilder<List<CategoryModel>>(
          stream: _service.getSubcategoriesStream(),
          builder: (context, snapshot) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _editingId == null
                                      ? 'Add subcategory'
                                      : 'Edit subcategory',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (_editingId != null)
                                TextButton(
                                  onPressed: _resetForm,
                                  child: const Text('Cancel'),
                                ),
                            ],
                          ),
                          AppSpacing.h15,
                          if (loadingMains)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          else
                            VendorDropdownFormField<String>(
                              value: mainCategories.any(
                                (c) => c.name == _selectedMainCategory,
                              )
                                  ? _selectedMainCategory
                                  : null,
                              label: 'Main category *',
                              hint: mainCategories.isEmpty
                                  ? 'Add a category first'
                                  : 'Select main category',
                              prefixIcon: Icons.category_outlined,
                              items: mainCategories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.name,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: mainCategories.isEmpty
                                  ? null
                                  : (v) => setState(
                                        () => _selectedMainCategory = v,
                                      ),
                              validator: (v) =>
                                  v == null || v.isEmpty
                                      ? 'Select a main category'
                                      : null,
                            ),
                          AppSpacing.h15,
                          VendorTextFormField(
                            controller: _nameController,
                            label: 'Subcategory name *',
                            hint: 'Ex: Fresh milk',
                            prefixIcon: Icons.label_outline,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter subcategory name'
                                    : null,
                          ),
                          AppSpacing.h15,
                          VendorTextFormField(
                            controller: _orderController,
                            label: 'Order number *',
                            hint: 'Ex: 1',
                            prefixIcon: Icons.format_list_numbered,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter order number'
                                    : null,
                          ),
                          AppSpacing.h15,
                          _ImagePickerTile(
                            imageBytes: _imageBytes,
                            existingImage: _existingImage,
                            label: 'Subcategory image',
                            onTap: _pickImage,
                          ),
                          AppSpacing.h20,
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Text(
                                      _editingId == null
                                          ? 'Add subcategory'
                                          : 'Update subcategory',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppSpacing.h20,
                Text(
                  'All subcategories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                AppSpacing.h10,
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if ((snapshot.data ?? const []).isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No subcategories yet. Add one above.',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...snapshot.data!.map(
                    (sub) => _SubcategoryListTile(
                      subcategory: sub,
                      onEdit: () => _startEdit(sub),
                      onDelete: () => _confirmDelete(sub),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategoryFormCard extends StatelessWidget {
  const _CategoryFormCard({
    required this.formKey,
    required this.title,
    required this.nameController,
    required this.orderController,
    required this.imageBytes,
    required this.existingImage,
    required this.saving,
    required this.isEditing,
    required this.onPickImage,
    required this.onSave,
    this.onCancelEdit,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final TextEditingController nameController;
  final TextEditingController orderController;
  final Uint8List? imageBytes;
  final String? existingImage;
  final bool saving;
  final bool isEditing;
  final VoidCallback onPickImage;
  final VoidCallback onSave;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onCancelEdit != null)
                    TextButton(
                      onPressed: onCancelEdit,
                      child: const Text('Cancel'),
                    ),
                ],
              ),
              AppSpacing.h15,
              VendorTextFormField(
                controller: nameController,
                label: 'Category name *',
                hint: 'Ex: Groceries',
                prefixIcon: Icons.category_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Enter category name'
                        : null,
              ),
              AppSpacing.h15,
              VendorTextFormField(
                controller: orderController,
                label: 'Order number *',
                hint: 'Ex: 1',
                prefixIcon: Icons.format_list_numbered,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Enter order number'
                        : null,
              ),
              AppSpacing.h15,
              _ImagePickerTile(
                imageBytes: imageBytes,
                existingImage: existingImage,
                label: 'Category image',
                onTap: onPickImage,
              ),
              AppSpacing.h20,
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update category' : 'Add category',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.imageBytes,
    required this.existingImage,
    required this.label,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final String? existingImage;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (imageBytes != null) {
      preview = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (existingImage != null && existingImage!.isNotEmpty) {
      preview = Image.network(
        existingImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          color: Colors.grey[400],
        ),
      );
    } else {
      preview = Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[500]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        AppSpacing.h10,
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: preview,
          ),
        ),
        AppSpacing.h5,
        Text(
          'Tap to upload image',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            category.image,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 20),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Order: ${category.order}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppColor.primary.withValues(alpha: 0.9)),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryListTile extends StatelessWidget {
  const _SubcategoryListTile({
    required this.subcategory,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel subcategory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            subcategory.image,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 20),
            ),
          ),
        ),
        title: Text(
          subcategory.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${subcategory.mainCategory ?? 'N/A'} · Order: ${subcategory.order}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppColor.primary.withValues(alpha: 0.9)),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
