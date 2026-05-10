import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/preference_service.dart';
import 'login_screen.dart';
import '../main_navigation_screen.dart';

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
      // Check if vendor is logged in
      final isLoggedIn = await PreferenceService.isLoggedIn();
      
      if (isLoggedIn) {
        // Get stored vendor ID
        final vendorId = await PreferenceService.getVendorId();
        
        if (vendorId != null && vendorId.isNotEmpty) {
          // Fetch vendor data from Firestore
          final vendor = await _authService.getVendorById(vendorId);
          
          if (vendor != null && vendor.isActive) {
            // Vendor is logged in and active, navigate to main navigation screen
            if (mounted) {
              setState(() {
                _initialScreen = MainNavigationScreen(vendor: vendor);
                _isLoading = false;
              });
            }
            return;
          } else {
            // Vendor not found or inactive, clear preferences
            await PreferenceService.clearVendorData();
          }
        }
      }
      
      // Not logged in or invalid session, show login screen
      if (mounted) {
        setState(() {
          _initialScreen = const LoginScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error checking login status, show login screen
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

