import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickgrocery_vendor/controllers/auth_controller.dart';
import 'package:quickgrocery_vendor/style/app_color.dart';
import 'package:quickgrocery_vendor/utils/app_spacing.dart';
import 'package:quickgrocery_vendor/view/auth/widgets/signup_image_upload.dart';
import 'package:quickgrocery_vendor/view/auth/widgets/signup_section_card.dart';
import 'login_screen.dart';

class VendorSignupScreen extends StatefulWidget {
  const VendorSignupScreen({super.key});

  @override
  State<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends State<VendorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();
  final _picker = ImagePicker();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  File? _vendorImage;
  File? _shopLogo;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _authController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _pickImage(bool vendor) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      if (vendor) {
        _vendorImage = File(file.path);
      } else {
        _shopLogo = File(file.path);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorImage == null) {
      _snack('Please upload vendor image');
      return;
    }
    if (_shopLogo == null) {
      _snack('Please upload shop logo');
      return;
    }
    if (_authController.isSignupLoading) return;

    final result = await _authController.submitVendorSignup(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      shopName: _shopNameController.text.trim(),
      shopAddress: _shopAddressController.text.trim(),
      vendorImage: _vendorImage!,
      shopLogo: _shopLogo!,
    );

    if (!mounted) return;
    if (!result.isSuccess) {
      _snack(result.errorMessage ?? 'Signup failed');
      return;
    }

    _snack(
      result.message ?? 'Request submitted successfully. Wait for admin approval.',
      error: false,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, _) {
        final loading = _authController.isSignupLoading;
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
            title: const Text('Vendor Sign Up'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Apply to sell on Quick Groceries',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.h10,
                    Text(
                      'Submit your details for admin approval. You can log in after approval.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    AppSpacing.h20,
                    SignupSectionCard(
                      title: 'Personal information',
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _firstNameController,
                                  label: 'First name',
                                  enabled: !loading,
                                  validator: _required,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  controller: _lastNameController,
                                  label: 'Last name',
                                  enabled: !loading,
                                  validator: _required,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h15,
                          _field(
                            controller: _phoneController,
                            label: 'Phone (+91)',
                            keyboard: TextInputType.phone,
                            enabled: !loading,
                            validator: (v) {
                              if (v == null || v.trim().length < 10) {
                                return 'Enter valid phone';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.h15,
                          SignupImageUpload(
                            label: 'Vendor image (1:1)',
                            file: _vendorImage,
                            onTap: loading ? null : () => _pickImage(true),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h15,
                    SignupSectionCard(
                      title: 'Account',
                      icon: Icons.lock_outline,
                      child: Column(
                        children: [
                          _field(
                            controller: _emailController,
                            label: 'Email',
                            keyboard: TextInputType.emailAddress,
                            enabled: !loading,
                            validator: _emailValidator,
                          ),
                          AppSpacing.h15,
                          _field(
                            controller: _passwordController,
                            label: 'Password',
                            obscure: _obscurePassword,
                            enabled: !loading,
                            onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            validator: (v) =>
                                v != null && v.length >= 8 ? null : 'Min 8 chars',
                          ),
                          AppSpacing.h15,
                          _field(
                            controller: _confirmController,
                            label: 'Confirm password',
                            obscure: _obscureConfirm,
                            enabled: !loading,
                            onToggleObscure: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            validator: (v) => v != _passwordController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h15,
                    SignupSectionCard(
                      title: 'Shop information',
                      icon: Icons.store_outlined,
                      child: Column(
                        children: [
                          _field(
                            controller: _shopNameController,
                            label: 'Shop name',
                            enabled: !loading,
                            validator: _required,
                          ),
                          AppSpacing.h15,
                          _field(
                            controller: _shopAddressController,
                            label: 'Shop address',
                            maxLines: 2,
                            enabled: !loading,
                            validator: _required,
                          ),
                          AppSpacing.h15,
                          SignupImageUpload(
                            label: 'Shop logo (1:1)',
                            file: _shopLogo,
                            onTap: loading ? null : () => _pickImage(false),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Submit for approval',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                      child: const Text('Already approved? Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final t = v.trim();
    if (!t.contains('@') || !t.contains('.')) return 'Invalid email';
    return null;
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    required String? Function(String?) validator,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: enabled ? onToggleObscure : null,
              ),
      ),
      validator: validator,
    );
  }
}
