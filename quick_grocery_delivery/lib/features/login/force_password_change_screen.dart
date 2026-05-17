import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/core/auth/delivery_session_prefs.dart';
import 'package:quick_grocery_delivery/core/auth/partner_auth_api.dart';
import 'package:quick_grocery_delivery/core/auth/password_validation.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';

class ForcePasswordChangeScreen extends StatefulWidget {
  const ForcePasswordChangeScreen({super.key, required this.partnerId});

  final String partnerId;

  @override
  State<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
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
      final sessionVersion = await _api.updatePassword(
        partnerId: widget.partnerId,
        newPassword: _passwordController.text,
      );
      await DeliverySessionPrefs.saveLogin(
        deliveryBoyId: widget.partnerId,
        sessionVersion: sessionVersion,
        forcePasswordChange: false,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set a new password to continue. Min 8 characters, 1 uppercase, 1 number.',
            ),
            const SizedBox(height: 20),
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
              title: 'Continue',
              isLoading: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
