import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/auth/vendor_auth_errors.dart';
import '../../core/fcm_bootstrap.dart';
import '../../models/vendor_model.dart';
import '../../services/vendor_auth_service.dart';
import 'login_screen.dart';
import '../main_navigation_screen.dart';
import 'force_password_change_screen.dart';
import 'vendor_status_gate.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final VendorAuthService _authService = VendorAuthService();
  bool _isLoading = true;
  Widget _initialScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final vendor = await _authService.restoreSession();
      if (vendor != null) {
        final blocked = VendorModel.loginBlockedReason(vendor.toFirestore());
        if (blocked == null) {
          final forceChange = await _authService.shouldForcePasswordChange();
          try {
            await VendorFcmBootstrap.configureForVendor(vendor.id);
          } catch (e) {
            VendorAuthErrors.logDebug('FCM restore skipped: $e');
          }
          if (mounted) {
            setState(() {
              _initialScreen = forceChange
                  ? ForcePasswordChangeScreen(vendor: vendor)
                  : VendorStatusGate(
                      vendorId: vendor.id,
                      child: MainNavigationScreen(vendor: vendor),
                    );
              _isLoading = false;
            });
          }
          return;
        }
        VendorAuthErrors.logDebug('restore blocked: $blocked');
      }
      await _authService.logout();
    } catch (e, st) {
      VendorAuthErrors.logDebug('auth wrapper error: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: st);
      }
      await _authService.logout();
    }

    if (mounted) {
      setState(() {
        _initialScreen = const LoginScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _initialScreen;
  }
}
