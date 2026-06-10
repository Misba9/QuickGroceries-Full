import 'package:quickgrocery/core/auth/phone_auth_coordinator.dart';

/// @deprecated Use [PhoneAuthCoordinator.clearAuthRoutes] instead.
abstract final class PhoneSignInNavigation {
  static void clearAuthRoutes() => PhoneAuthCoordinator.clearAuthRoutes();
}
