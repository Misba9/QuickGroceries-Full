import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/auth/auth_session_manager.dart';
import 'package:quickgrocery/core/auth/phone_sign_in_navigation.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';

/// Pushes phone login without tearing down the guest home shell.
abstract final class GuestLoginLauncher {
  static bool _loginPushInFlight = false;

  static Future<void> launch(BuildContext context, WidgetRef ref) async {
    // Prevent double-tap stacking multiple login routes.
    if (_loginPushInFlight ||
        appRouteObserver.isCurrent(AppRoutes.login) ||
        appRouteObserver.isCurrent(AppRoutes.otp)) {
      return;
    }
    _loginPushInFlight = true;
    try {
      AuthSessionManager.prepareNewLogin();
      PhoneSignInNavigation.reset();
      final nav = rootNavigatorKey.currentState ??
          Navigator.of(context, rootNavigator: true);
      await nav.push<void>(AppPageRoutes.login());
    } finally {
      _loginPushInFlight = false;
    }
  }
}
