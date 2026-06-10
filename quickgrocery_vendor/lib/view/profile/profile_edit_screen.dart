import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_grocery_geo/quick_grocery_geo.dart';
import '../../models/vendor_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/keyboard_safe_body.dart';
import '../../widgets/vendor_form_fields.dart';

class ProfileEditScreen extends StatefulWidget {
  final VendorModel vendor;

  const ProfileEditScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  final GeocodeService _geocodeService = GeocodeService();
  bool _isLoading = false;
  bool _isUploadingImage = false;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  File? _selectedVendorImage;
  File? _selectedShopImage;
  String? _vendorImageUrl;
  String? _shopImageUrl;

  @override
  void initState() {
    super.initState();
    _populateForm();
  }

  void _populateForm() {
    _firstNameController.text = widget.vendor.firstName;
    _lastNameController.text = widget.vendor.lastName;
    _phoneController.text = widget.vendor.phone;
    _emailController.text = widget.vendor.email;
    _shopNameController.text = widget.vendor.shopName;
    _shopAddressController.text = widget.vendor.shopAddress;
    _vendorImageUrl = widget.vendor.vendorImage;
    _shopImageUrl = widget.vendor.shopImage;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {required bool isVendorImage}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isVendorImage) {
            _selectedVendorImage = File(pickedFile.path);
            _vendorImageUrl = null; // Clear old URL when new image is selected
          } else {
            _selectedShopImage = File(pickedFile.path);
            _shopImageUrl = null; // Clear old URL when new image is selected
          }
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

  Future<String?> _uploadVendorImage() async {
    if (_selectedVendorImage == null) {
      return _vendorImageUrl; // Return existing URL if no new image
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final url = await _storageService.uploadProductImage(
        imageFile: _selectedVendorImage!,
        vendorId: widget.vendor.id,
        productId: 'vendor_profile',
      );
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading vendor image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<String?> _uploadShopImage() async {
    if (_selectedShopImage == null) {
      return _shopImageUrl; // Return existing URL if no new image
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final url = await _storageService.uploadProductImage(
        imageFile: _selectedShopImage!,
        vendorId: widget.vendor.id,
        productId: 'shop_image',
      );
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading shop image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload images first if new ones are selected
        String? finalVendorImageUrl = await _uploadVendorImage();
        String? finalShopImageUrl = await _uploadShopImage();

        if (finalVendorImageUrl == null && _selectedVendorImage != null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (finalShopImageUrl == null && _selectedShopImage != null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Resolve store coordinates from saved values or geocode the address.
        double? shopLat = widget.vendor.shopLat;
        double? shopLng = widget.vendor.shopLng;
        final addressChanged =
            _shopAddressController.text.trim() != widget.vendor.shopAddress.trim();
        if (addressChanged ||
            !GpsPoint.isValidCoord(shopLat, shopLng)) {
          final geocoded =
              await _geocodeService.geocodeAddress(_shopAddressController.text.trim());
          if (geocoded == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Could not locate shop address. Check the address and try again.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
          shopLat = geocoded.latitude;
          shopLng = geocoded.longitude;
        }

        // Create updated vendor model
        final updatedVendor = VendorModel(
          id: widget.vendor.id,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: widget.vendor.password, // Keep existing password
          shopName: _shopNameController.text.trim(),
          shopAddress: _shopAddressController.text.trim(),
          shopLat: shopLat,
          shopLng: shopLng,
          vendorImage: finalVendorImageUrl ?? widget.vendor.vendorImage,
          shopImage: finalShopImageUrl ?? widget.vendor.shopImage,
          isActive: widget.vendor.isActive,
        );

        // Update vendor in Firestore
        await _authService.updateVendor(updatedVendor);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedVendor);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: ${e.toString()}'),
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

  void _showImagePickerOptions({required bool isVendorImage}) {
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
                _pickImage(ImageSource.gallery, isVendorImage: isVendorImage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isVendorImage: isVendorImage);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(16),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vendor Image Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedVendorImage != null
                              ? FileImage(_selectedVendorImage!)
                              : (_vendorImageUrl != null && _vendorImageUrl!.isNotEmpty)
                                  ? NetworkImage(_vendorImageUrl!)
                                  : null,
                          child: (_selectedVendorImage == null &&
                                  (_vendorImageUrl == null || _vendorImageUrl!.isEmpty))
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[600],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColor.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              color: Colors.black,
                              onPressed: () => _showImagePickerOptions(isVendorImage: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h10,
                    const Text(
                      'Vendor Photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.h20,

              // Shop Image Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            image: _selectedShopImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedShopImage!),
                                    fit: BoxFit.cover,
                                  )
                                : (_shopImageUrl != null && _shopImageUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(_shopImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: (_selectedShopImage == null &&
                                  (_shopImageUrl == null || _shopImageUrl!.isEmpty))
                              ? Icon(
                                  Icons.store,
                                  size: 60,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColor.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              color: Colors.black,
                              onPressed: () => _showImagePickerOptions(isVendorImage: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h10,
                    const Text(
                      'Shop Photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _firstNameController,
                label: 'First Name *',
                hint: 'Enter first name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _lastNameController,
                label: 'Last Name *',
                hint: 'Enter last name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _phoneController,
                label: 'Phone *',
                hint: 'Enter phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _emailController,
                label: 'Email *',
                hint: 'Enter email address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _shopNameController,
                label: 'Shop Name *',
                hint: 'Enter shop name',
                prefixIcon: Icons.store_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your shop name';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              VendorTextFormField(
                controller: _shopAddressController,
                label: 'Shop Address *',
                hint: 'Enter shop address',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your shop address';
                  }
                  return null;
                },
              ),
              AppSpacing.h20,

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isUploadingImage) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: (_isLoading || _isUploadingImage)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
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
      ),
    );
  }
}

