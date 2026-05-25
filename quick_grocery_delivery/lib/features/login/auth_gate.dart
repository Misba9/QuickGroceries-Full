import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/core/auth/delivery_auth_service.dart';
import 'package:quick_grocery_delivery/core/auth/delivery_session_prefs.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:quick_grocery_delivery/features/login/force_password_change_screen.dart';
import 'package:quick_grocery_delivery/features/login/login_screen.dart';

/// Resolves initial route: login, home, or forced password change.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final DeliveryAuthService _authService = DeliveryAuthService();

  Widget _screen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final deliveryBoyId = await _authService.restoreSession();
      if (deliveryBoyId == null || deliveryBoyId.isEmpty) {
        if (mounted) setState(() => _screen = const LoginScreen());
        return;
      }

      final force = await DeliverySessionPrefs.forcePasswordChange();
      if (mounted) {
        setState(() {
          _screen = force
              ? ForcePasswordChangeScreen(partnerId: deliveryBoyId)
              : const HomeScreen();
        });
      }
    } catch (_) {
      await _authService.logout();
      if (mounted) setState(() => _screen = const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) => _screen;
}
