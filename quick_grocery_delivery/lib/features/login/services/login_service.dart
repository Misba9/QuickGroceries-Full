import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/core/auth/delivery_session_prefs.dart';
import 'package:quick_grocery_delivery/core/auth/partner_auth_api.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:quick_grocery_delivery/features/login/force_password_change_screen.dart';

class LoginService extends ChangeNotifier {
  bool isLoading = false;
  bool obscurePassword = true;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final PartnerAuthApi _api = PartnerAuthApi();

  Future<bool> validateStoredSession() async {
    final id = await DeliverySessionPrefs.deliveryBoyId();
    if (id == null || id.isEmpty) return false;
    final version = await DeliverySessionPrefs.sessionVersion();
    if (version == null) return true;
    final check = await _api.checkSession(
      partnerId: id,
      sessionVersion: version,
    );
    if (check['valid'] == true) return true;
    await DeliverySessionPrefs.clear();
    return false;
  }

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

      final result = await _api.login(email, password);
      if (!context.mounted) return;
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?.toString() ?? 'Invalid email or password.',
            ),
          ),
        );
        return;
      }

      final partnerId = result['partnerId'] as String?;
      if (partnerId == null || partnerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password.')),
        );
        return;
      }

      final sessionVersion = (result['sessionVersion'] as num?)?.toInt() ?? 0;
      final forceChange = result['forcePasswordChange'] == true;

      await DeliverySessionPrefs.saveLogin(
        deliveryBoyId: partnerId,
        sessionVersion: sessionVersion,
        forcePasswordChange: forceChange,
      );

      if (!context.mounted) return;

      if (forceChange) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ForcePasswordChangeScreen(partnerId: partnerId),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
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
    await DeliverySessionPrefs.clear();
    emailController.clear();
    passwordController.clear();
    notifyListeners();
  }
}
