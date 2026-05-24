import 'package:flutter/foundation.dart';

import '../core/auth/vendor_login_result.dart';
import '../models/vendor_model.dart';
import 'firebase_service.dart';
import 'vendor_auth_service.dart';

/// Back-compat facade — delegates to [VendorAuthService].
class AuthService {
  AuthService({VendorAuthService? vendorAuth})
      : _vendorAuth = vendorAuth ?? VendorAuthService();

  final VendorAuthService _vendorAuth;

  static const String vendorsCollection = FirebaseService.vendorsCollection;

  Future<VendorLoginResult> loginVendor(String email, String password) =>
      _vendorAuth.login(email: email, password: password);

  Future<bool> shouldForcePasswordChange() =>
      _vendorAuth.shouldForcePasswordChange();

  Future<bool> isSessionValid(String vendorId) =>
      _vendorAuth.isPartnerSessionValid(vendorId);

  Future<VendorModel?> getVendorById(String vendorId) =>
      _vendorAuth.getVendorById(vendorId);

  Future<void> updateVendor(VendorModel vendor) async {
    try {
      await _vendorAuth.updateVendor(vendor);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VendorAuth] updateVendor failed: $e');
      }
      rethrow;
    }
  }

  Future<void> logout() => _vendorAuth.logout();
}
