import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/core/auth/delivery_auth_service.dart';
import 'package:quick_grocery_delivery/core/fcm_bootstrap.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:quick_grocery_delivery/features/login/force_password_change_screen.dart';

class LoginService extends ChangeNotifier {
  LoginService({DeliveryAuthService? authService})
      : _authService = authService ?? DeliveryAuthService();

  bool isLoading = false;
  bool obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DeliveryAuthService _authService;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<bool> validateStoredSession() =>
      _authService.validateStoredSession();

  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      final result = await _authService.login(email: email, password: password);
      if (!context.mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Login failed.')),
        );
        return;
      }

      final deliveryBoyId = result.deliveryBoyId;
      if (deliveryBoyId == null || deliveryBoyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery account not found.')),
        );
        return;
      }

      if (result.forcePasswordChange) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ForcePasswordChangeScreen(partnerId: deliveryBoyId),
          ),
        );
        return;
      }

      await DeliveryFcmBootstrap.configureForRider(deliveryBoyId);
      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emailController.clear();
    passwordController.clear();
    notifyListeners();
  }
}
