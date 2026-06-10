import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/core/navigation/root_back_handler.dart';
import 'package:quickgrocery_vendor/controllers/auth_controller.dart';
import 'package:quickgrocery_vendor/core/fcm_bootstrap.dart';
import 'package:quickgrocery_vendor/style/app_color.dart';
import 'package:quickgrocery_vendor/utils/app_spacing.dart';
import 'package:quickgrocery_vendor/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery_vendor/widgets/vendor_form_fields.dart';
import 'package:quickgrocery_vendor/widgets/vendor_logo.dart';
import '../main_navigation_screen.dart';
import 'forgot_password/forgot_password_email_screen.dart';
import 'force_password_change_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_authController.isLoading) return;

    final result = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      _showSnack(result.errorMessage ?? 'Vendor account not found');
      return;
    }

    final vendor = result.vendor!;
    try {
      await VendorFcmBootstrap.configureForVendor(vendor.id);
    } catch (_) {}

    if (!mounted) return;
    final forceChange = await _authController.shouldForcePasswordChange();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => forceChange
            ? ForcePasswordChangeScreen(vendor: vendor)
            : MainNavigationScreen(vendor: vendor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, _) {
        final isLoading = _authController.isLoading;
        return RootBackHandler(
          blockPop: isLoading,
          child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: KeyboardSafeBody(
              padding: const EdgeInsets.all(24),
              fillMinHeight: true,
              centerWhenFilling: true,
              child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VendorLogo(
                        height: 130,
                        subtitle: 'Sign in to manage your store',
                      ),
                      AppSpacing.h20,
                      AppSpacing.h20,
                      VendorTextFormField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final v = value.trim();
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      AppSpacing.h20,
                      VendorTextFormField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onFieldSubmitted: (_) => _handleLogin(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordEmailScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.h10,
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      AppSpacing.h10,
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VendorSignupScreen(),
                                  ),
                                );
                              },
                        child: Text(
                          'New vendor? Create account',
                          style: TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ),
        );
      },
    );
  }
}
