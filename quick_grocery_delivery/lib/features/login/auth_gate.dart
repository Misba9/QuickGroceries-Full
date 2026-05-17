import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/core/auth/delivery_session_prefs.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:quick_grocery_delivery/features/login/force_password_change_screen.dart';
import 'package:quick_grocery_delivery/features/login/login_screen.dart';
import 'package:quick_grocery_delivery/features/login/services/login_service.dart';

/// Resolves initial route: login, home, or forced password change.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Widget _screen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final id = await DeliverySessionPrefs.deliveryBoyId();
    if (id == null || id.isEmpty) {
      setState(() => _screen = const LoginScreen());
      return;
    }

    final loginService = LoginService();
    final valid = await loginService.validateStoredSession();
    if (!valid) {
      setState(() => _screen = const LoginScreen());
      return;
    }

    final force = await DeliverySessionPrefs.forcePasswordChange();
    setState(() {
      _screen = force
          ? ForcePasswordChangeScreen(partnerId: id)
          : const HomeScreen();
    });
  }

  @override
  Widget build(BuildContext context) => _screen;
}
