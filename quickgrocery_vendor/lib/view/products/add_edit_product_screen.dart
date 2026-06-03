import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/product_settings.dart';
import '../../models/vendor_model.dart';
import '../../models/category_model.dart';
import '../../constants/product_image_limits.dart';
import '../../models/product_image_slot.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/product_image_upload_service.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/keyboard_safe_body.dart';
import '../../widgets/vendor_form_fields.dart';
import 'widgets/product_images_upload_section.dart';
import 'widgets/product_settings_panel.dart';

class AddEditProductScreen extends StatefulWidget {
  final VendorModel vendor;
  final ProductModel? product;

  const AddEditProductScreen({
    super.key,
    required this.vendor,
    this.product,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _imageUploadService = ProductImageUploadService();
  bool _isLoading = false;
  bool _isUploadingImages = false;
  double? _uploadProgress;
  bool _isLoadingCategories = false;

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();
  final _maxOrderController = TextEditingController();
  final _priceController = TextEditingController();
  final _slashedPriceController = TextEditingController();
  final _unitPerItemController = TextEditingController();

  // Category and Subcategory
  List<CategoryModel> _categories = [];
  List<CategoryModel> _subcategories = [];
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedCategoryName;
  String? _selectedSubcategoryName;

  ProductSettings _settings = const ProductSettings();

  List<ProductImageSlot> _imageSlots = [];
  List<String> _initialGalleryUrls = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _populateForm(widget.product!);
      _initialGalleryUrls = widget.product!.galleryUrls;
      _imageSlots = ProductImageSlot.fromUrls(_initialGalleryUrls);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });

      // If editing a product, try to find and select the category
      if (widget.product != null && _categories.isNotEmpty) {
        final categoryName = widget.product!.category;
        try {
          final category = _categories.firstWhere(
            (cat) => cat.name == categoryName,
          );
          setState(() {
            _selectedCategoryId = category.id;
            _selectedCategoryName = category.name;
          });
          // Load subcategories using category name since main_category stores the name
          await _loadSubcategories(category.name);
        } catch (e) {
          // Category not found, leave unselected
          print('Category "$categoryName" not found in categories list');
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSubcategories(String categoryName) async {
    try {
      // Load subcategories using category name since main_category field stores the category name
      final subcategories = await _categoryService.getSubcategoriesByCategory(categoryName);
      setState(() {
        _subcategories = subcategories;
      });

      // If editing a product, try to find and select the subcategory
      if (widget.product != null && 
          widget.product!.subcategory != null && 
          _subcategories.isNotEmpty) {
        final subcategoryName = widget.product!.subcategory!;
        try {
          final subcategory = _subcategories.firstWhere(
            (sub) => sub.name == subcategoryName,
          );
          setState(() {
            _selectedSubcategoryId = subcategory.id;
            _selectedSubcategoryName = subcategory.name;
          });
        } catch (e) {
          // Subcategory not found, leave unselected
          print('Subcategory "$subcategoryName" not found in subcategories list');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subcategories: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateForm(ProductModel product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _unitController.text = product.unit;
    _stockController.text = product.stock;
    _maxOrderController.text = product.maxOrder;
    _priceController.text = product.price;
    _slashedPriceController.text = product.slashedPrice;
    _unitPerItemController.text = product.unitPerItem;
    _settings = product.settings;
    // Category and subcategory will be set in _loadCategories after categories are loaded
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _maxOrderController.dispose();
    _priceController.dispose();
    _slashedPriceController.dispose();
    _unitPerItemController.dispose();
    super.dispose();
  }

  Future<List<String>> _uploadGalleryImages() async {
    setState(() {
      _isUploadingImages = true;
      _uploadProgress = 0;
    });

    try {
      final productId = widget.product?.id;
      final urls = await _imageUploadService.uploadSlots(
        slots: _imageSlots,
        vendorId: widget.vendor.id,
        productId: productId?.isNotEmpty == true ? productId : null,
        onProgress: (done, total) {
          if (!mounted || total == 0) return;
          setState(() => _uploadProgress = done / total);
        },
      );

      await _imageUploadService.deleteRemovedUrls(
        previousUrls: _initialGalleryUrls,
        nextUrls: urls,
      );

      return urls;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_imageSlots.length < ProductImageLimits.minImages) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please add at least 1 product image'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        final galleryUrls = await _uploadGalleryImages();
        if (galleryUrls.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Upload failed, retry again'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        final product = ProductModel(
          id: widget.product?.id ?? '',
          name: _nameController.text.trim(),
          image: galleryUrls.first,
          createdAt: widget.product?.createdAt ?? Timestamp.now(),
          description: _descriptionController.text.trim(),
          category: _selectedCategoryName ?? '',
          subcategory: _selectedSubcategoryName,
          unit: _unitController.text.trim(),
          stock: _stockController.text.trim(),
          maxOrder: _maxOrderController.text.trim(),
          price: _priceController.text.trim(),
          slashedPrice: _slashedPriceController.text.trim(),
          totalSold: widget.product?.totalSold ?? 0,
          vendorId: widget.vendor.id,
          settings: _settings,
          lastEdited: Timestamp.now(),
          unitPerItem: _unitPerItemController.text.trim(),
          favorites: widget.product?.favorites ?? [],
          shopName: widget.vendor.shopName,
          images: galleryUrls,
          videos: widget.product?.videos ?? [],
          specialCat: widget.product?.specialCat ?? '',
        );

        if (widget.product != null) {
          await _productService.updateProduct(product);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Images uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          await _productService.addProduct(product);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
      ),
      resizeToAvoidBottomInset: true,
      body: KeyboardSafeBody(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductImagesUploadSection(
                initialUrls: _initialGalleryUrls,
                isUploading: _isUploadingImages,
                uploadProgress: _uploadProgress,
                onChanged: (slots) => setState(() => _imageSlots = slots),
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _nameController,
                label: 'Product Name *',
                hint: 'Enter product name',
                prefixIcon: Icons.shopping_bag_outlined,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _descriptionController,
                label: 'Description *',
                hint: 'Enter product description',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : VendorDropdownFormField<String>(
                      value: _selectedCategoryId,
                      label: 'Category *',
                      hint: 'Select category',
                      prefixIcon: Icons.category_outlined,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          final selectedCategory = _categories.firstWhere(
                            (cat) => cat.id == value,
                          );
                          setState(() {
                            _selectedCategoryId = value;
                            _selectedCategoryName = selectedCategory.name;
                            _selectedSubcategoryId = null;
                            _selectedSubcategoryName = null;
                            _subcategories = [];
                          });
                          _loadSubcategories(selectedCategory.name);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
              AppSpacing.h20,

              if (_selectedCategoryId != null) ...[
                VendorDropdownFormField<String>(
                  value: _selectedSubcategoryId,
                  label: 'Subcategory (Optional)',
                  hint: 'Select subcategory',
                  prefixIcon: Icons.subdirectory_arrow_right,
                  items: _subcategories.isEmpty
                      ? [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No subcategories available'),
                          ),
                        ]
                      : [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._subcategories.map((subcategory) {
                            return DropdownMenuItem<String>(
                              value: subcategory.id,
                              child: Text(subcategory.name),
                            );
                          }),
                        ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedSubcategoryId = value;
                      _selectedSubcategoryName = value != null
                          ? _subcategories
                              .firstWhere((sub) => sub.id == value)
                              .name
                          : null;
                    });
                  },
                ),
                AppSpacing.h20,
              ],

              Row(
                children: [
                  Expanded(
                    child: VendorTextFormField(
                      controller: _priceController,
                      label: 'Price *',
                      hint: '0.00',
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter price';
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.w15,
                  Expanded(
                    child: VendorTextFormField(
                      controller: _slashedPriceController,
                      label: 'Discount Price *',
                      hint: '0.00',
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter discount price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,

              Row(
                children: [
                  Expanded(
                    child: VendorTextFormField(
                      controller: _stockController,
                      label: 'Stock *',
                      hint: 'Enter stock quantity',
                      prefixIcon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter stock';
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.w15,
                  Expanded(
                    child: VendorTextFormField(
                      controller: _maxOrderController,
                      label: 'Max Order *',
                      hint: 'Max per order',
                      prefixIcon: Icons.shopping_cart_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter max order';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,

              Row(
                children: [
                  Expanded(
                    child: VendorTextFormField(
                      controller: _unitController,
                      label: 'Unit *',
                      hint: 'e.g., kg, pcs',
                      prefixIcon: Icons.scale_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter unit';
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.w15,
                  Expanded(
                    child: VendorTextFormField(
                      controller: _unitPerItemController,
                      label: 'Weight *',
                      hint: 'e.g., 1 kg',
                      prefixIcon: Icons.format_list_numbered,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter weight';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,

              ProductSettingsPanel(
                productId: widget.product?.id.isNotEmpty == true
                    ? widget.product!.id
                    : null,
                initialProduct: widget.product,
                initialSettings: _settings,
                onLocalChanged: (s) {
                  if (_settings == s) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _settings != s) {
                      setState(() => _settings = s);
                    }
                  });
                },
              ),
              AppSpacing.h20,
              AppSpacing.h10,

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isUploadingImages) ? null : _saveProduct,
                  child: _isLoading || _isUploadingImages
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          widget.product != null ? 'Update Product' : 'Add Product',
                        ),
                ),
              ),
              AppSpacing.h20,
            ],
          ),
        ),
      ),
    );
  }
}
