import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../models/vendor_model.dart';
import '../../models/category_model.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../services/category_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';

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
  final _storageService = StorageService();
  final _categoryService = CategoryService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingImage = false;
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

  bool _isActive = true;
  bool _isFlashSale = false;
  bool _isTodaysBest = false;
  bool _isMostSelling = false;

  File? _selectedImage;
  String? _imageUrl; // URL from Firestore or uploaded image

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _populateForm(widget.product!);
      _imageUrl = widget.product!.image;
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
    _isActive = product.isActive;
    _isFlashSale = product.isFlashSale;
    _isTodaysBest = product.isTodaysBest;
    _isMostSelling = product.isMostSelling;
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageUrl = null; // Clear old URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _imageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      // If no new image selected, return existing URL
      return _imageUrl;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Delete old image if updating product
      if (widget.product != null && _imageUrl != null && _imageUrl!.isNotEmpty) {
        try {
          await _storageService.deleteImage(_imageUrl!);
        } catch (e) {
          // Continue even if deletion fails
          print('Error deleting old image: $e');
        }
      }

      // Upload new image
      final String downloadUrl = await _storageService.uploadProductImage(
        imageFile: _selectedImage!,
        vendorId: widget.vendor.id,
        productId: widget.product?.id,
      );

      setState(() {
        _isUploadingImage = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      rethrow;
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image first if a new one is selected
        String? finalImageUrl = await _uploadImage();

        if (finalImageUrl == null || finalImageUrl.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a product image'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        final product = ProductModel(
          id: widget.product?.id ?? '',
          name: _nameController.text.trim(),
          image: finalImageUrl,
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
          isFlashSale: _isFlashSale,
          isActive: _isActive,
          lastEdited: Timestamp.now(),
          unitPerItem: _unitPerItemController.text.trim(),
          favorites: widget.product?.favorites ?? [],
          shopName: widget.vendor.shopName,
          isMostSelling: _isMostSelling,
          isTodaysBest: _isTodaysBest,
          images: widget.product?.images ?? [],
          videos: widget.product?.videos ?? [],
        );

        if (widget.product != null) {
          // Update existing product
          await _productService.updateProduct(product);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          // Add new product
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
              // Product Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Image *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.h15,
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _isUploadingImage
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _imageUrl != null && _imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            _imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      size: 48,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text('Error loading image'),
                                                  ],
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(
                                                child: CircularProgressIndicator(),
                                              );
                                            },
                                          ),
                                        )
                                      : const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Tap to add product image',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                        ),
                      ),
                      AppSpacing.h10,
                      Center(
                        child: TextButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _selectedImage != null || _imageUrl != null
                                ? 'Change Image'
                                : 'Select Image',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

              // Toggle Switches
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.h15,
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Product will be visible to customers'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: AppColor.primary,
                      ),
                      SwitchListTile(
                        title: const Text('Flash Sale'),
                        value: _isFlashSale,
                        onChanged: (value) {
                          setState(() {
                            _isFlashSale = value;
                          });
                        },
                        activeColor: AppColor.primary,
                      ),
                      SwitchListTile(
                        title: const Text("Today's Best"),
                        value: _isTodaysBest,
                        onChanged: (value) {
                          setState(() {
                            _isTodaysBest = value;
                          });
                        },
                        activeColor: AppColor.primary,
                      ),
                      SwitchListTile(
                        title: const Text('Most Selling'),
                        value: _isMostSelling,
                        onChanged: (value) {
                          setState(() {
                            _isMostSelling = value;
                          });
                        },
                        activeColor: AppColor.primary,
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.h20,
              AppSpacing.h10,

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isUploadingImage) ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading || _isUploadingImage
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
