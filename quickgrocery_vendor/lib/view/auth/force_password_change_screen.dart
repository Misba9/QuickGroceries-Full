import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/core/auth/partner_auth_api.dart';
import 'package:quickgrocery_vendor/core/auth/password_validation.dart';
import 'package:quickgrocery_vendor/models/vendor_model.dart';
import 'package:quickgrocery_vendor/services/preference_service.dart';
import 'package:quickgrocery_vendor/style/app_color.dart';
import 'package:quickgrocery_vendor/utils/app_spacing.dart';
import 'package:quickgrocery_vendor/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery_vendor/view/main_navigation_screen.dart';

class ForcePasswordChangeScreen extends StatefulWidget {
  const ForcePasswordChangeScreen({super.key, required this.vendor});

  final VendorModel vendor;

  @override
  State<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _api = PartnerAuthApi();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final sessionVersion = await _api.updatePassword(
        partnerId: widget.vendor.id,
        newPassword: _passwordController.text,
      );
      await PreferenceService.saveSessionVersion(sessionVersion);
      await PreferenceService.setForcePasswordChange(false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(vendor: widget.vendor),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your administrator requires you to set a new password before continuing.',
                ),
                AppSpacing.h20,
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: PasswordValidation.validate,
                ),
                AppSpacing.h15,
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => PasswordValidation.confirm(v, _passwordController.text),
                ),
                AppSpacing.h20,
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
