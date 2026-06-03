import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/controllers/auth_controller.dart';
import 'package:quickgrocery_vendor/core/auth/vendor_auth_errors.dart';
import 'package:quickgrocery_vendor/style/app_color.dart';
import 'package:quickgrocery_vendor/utils/app_spacing.dart';
import 'package:quickgrocery_vendor/widgets/keyboard_safe_body.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authController = AuthController();

  @override
  void dispose() {
    _emailController.dispose();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_authController.isResetLoading) return;

    final email = _emailController.text.trim().toLowerCase();
    try {
      final result = await _authController.sendPasswordReset(email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context);
    } on VendorAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(VendorAuthErrors.fromException(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, _) {
        final loading = _authController.isResetLoading;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black87,
            title: const Text('Forgot Password'),
          ),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: KeyboardSafeBody(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reset your password',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    AppSpacing.h10,
                    Text(
                      'We will send a password reset link using Firebase Authentication.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    AppSpacing.h20,
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !loading,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final t = v.trim();
                        if (!t.contains('@') || !t.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.h20,
                    SizedBox(
                      height: 50,
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
                                'Send reset email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
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
}
