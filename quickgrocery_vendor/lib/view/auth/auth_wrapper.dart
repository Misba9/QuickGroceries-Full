import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/preference_service.dart';
import 'login_screen.dart';
import '../main_navigation_screen.dart';
import 'force_password_change_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Widget _initialScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await PreferenceService.isLoggedIn();

      if (isLoggedIn) {
        final vendorId = await PreferenceService.getVendorId();

        if (vendorId != null && vendorId.isNotEmpty) {
          final sessionOk = await _authService.isSessionValid(vendorId);
          if (!sessionOk) {
            await PreferenceService.clearVendorData();
          } else {
            final vendor = await _authService.getVendorById(vendorId);

            if (vendor != null && vendor.isActive) {
              final forceChange =
                  await PreferenceService.getForcePasswordChange();
              if (mounted) {
                setState(() {
                  _initialScreen = forceChange
                      ? ForcePasswordChangeScreen(vendor: vendor)
                      : MainNavigationScreen(vendor: vendor);
                  _isLoading = false;
                });
              }
              return;
            } else {
              await PreferenceService.clearVendorData();
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _initialScreen = const LoginScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialScreen = const LoginScreen();
          _isLoading = false;
        });
      }
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
