import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/core/auth/partner_auth_api.dart';
import 'package:quick_grocery_delivery/core/auth/password_validation.dart';
import 'package:quick_grocery_delivery/features/login/login_screen.dart';
import 'package:quick_grocery_delivery/widgets/keyboard_safe_body.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  const ForgotPasswordResetScreen({super.key, required this.email});

  final String email;

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
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
    final err = PasswordValidation.validate(_passwordController.text);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final confirmErr = PasswordValidation.confirm(
      _confirmController.text,
      _passwordController.text,
    );
    if (confirmErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmErr)));
      return;
    }

    setState(() => _loading = true);
    try {
      await _api.completePasswordReset(
        widget.email,
        _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. Sign in with your new password.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Reset Password')),
      body: KeyboardSafeBody(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
                filled: true,
                fillColor: GlobalVariables.lightGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
                filled: true,
                fillColor: GlobalVariables.lightGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              height: size.height,
              width: size.width,
              title: 'Update Password',
              isLoading: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
