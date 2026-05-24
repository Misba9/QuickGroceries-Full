import 'dart:io';

import 'package:flutter/material.dart';

import '../core/auth/password_reset_result.dart';
import '../core/auth/vendor_auth_errors.dart';
import '../core/auth/vendor_login_result.dart';
import '../core/auth/vendor_signup_result.dart';
import '../models/vendor_model.dart';
import '../services/vendor_auth_service.dart';
import '../services/vendor_signup_service.dart';

/// UI-facing auth state for login, signup, and password reset.
class AuthController extends ChangeNotifier {
  AuthController({
    VendorAuthService? authService,
    VendorSignupService? signupService,
  })  : _auth = authService ?? VendorAuthService(),
        _signup = signupService ?? VendorSignupService();

  final VendorAuthService _auth;
  final VendorSignupService _signup;

  bool isLoading = false;
  bool isSignupLoading = false;
  bool isResetLoading = false;

  VendorAuthService get authService => _auth;

  Future<VendorLoginResult> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      return await _auth.login(email: email, password: password);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<VendorSignupResult> submitVendorSignup({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String shopName,
    required String shopAddress,
    required File vendorImage,
    required File shopLogo,
  }) async {
    isSignupLoading = true;
    notifyListeners();
    try {
      return await _signup.submitRequest(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        password: password,
        shopName: shopName,
        shopAddress: shopAddress,
        vendorImageFile: vendorImage,
        shopLogoFile: shopLogo,
      );
    } finally {
      isSignupLoading = false;
      notifyListeners();
    }
  }

  Future<PasswordResetResult> sendPasswordReset(String email) async {
    isResetLoading = true;
    notifyListeners();
    try {
      return await _auth.sendPasswordResetEmail(email);
    } on VendorAuthException {
      rethrow;
    } catch (e) {
      throw VendorAuthException(VendorAuthErrors.fromException(e));
    } finally {
      isResetLoading = false;
      notifyListeners();
    }
  }

  Future<VendorModel?> restoreSession() => _auth.restoreSession();

  Future<void> logout() => _auth.logout();

  Future<bool> shouldForcePasswordChange() => _auth.shouldForcePasswordChange();
}
