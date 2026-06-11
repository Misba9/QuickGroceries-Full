import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/auth/auth_session_manager.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/auth_floating_cart_guard.dart';
import 'package:quickgrocery/view/auth/screens/login_screen.dart';

/// Pushes phone login without tearing down the guest home shell.
abstract final class GuestLoginLauncher {
  static Future<void> launch(BuildContext context, WidgetRef ref) async {
    AuthSessionManager.prepareNewLogin();
    final nav = Navigator.of(context, rootNavigator: true);
    await nav.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.login),
        builder: (_) => const AuthFloatingCartGuard(child: LoginScreen()),
      ),
    );
  }
}
