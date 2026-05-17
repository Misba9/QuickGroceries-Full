import 'dart:io';
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
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.product != null ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
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

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'Enter product name',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Enter product description',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              // Category Dropdown
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        hintText: 'Select category',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                          // Load subcategories using category name since main_category stores the name
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

              // Subcategory Dropdown
              _selectedCategoryId == null
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<String>(
                      value: _selectedSubcategoryId,
                      decoration: InputDecoration(
                        labelText: 'Subcategory (Optional)',
                        hintText: 'Select subcategory',
                        prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _subcategories.isEmpty
                          ? [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No subcategories available'),
                              )
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

              // Price and Slashed Price Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price *',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.w15,
                  Expanded(
                    child: TextFormField(
                      controller: _slashedPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Slashed Price',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,

              // Stock and Max Order Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock *',
                        hintText: 'Enter stock',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.w15,
                  Expanded(
                    child: TextFormField(
                      controller: _maxOrderController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max Order *',
                        hintText: 'Enter max order',
                        prefixIcon: const Icon(Icons.shopping_cart_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              AppSpacing.h20,

              // Unit and Unit Per Item Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        hintText: 'e.g., kg, pcs',
                        prefixIcon: const Icon(Icons.scale_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  AppSpacing.w15,
                  Expanded(
                    child: TextFormField(
                      controller: _unitPerItemController,
                      decoration: InputDecoration(
                        labelText: 'Unit Per Item',
                        hintText: 'e.g., 1kg',
                        prefixIcon: const Icon(Icons.format_list_numbered),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                  if (_settings != s) setState(() => _settings = s);
                },
              ),
              AppSpacing.h20,
              AppSpacing.h10,

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isUploadingImages) ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
