import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'vendor_auth_errors.dart';

/// Cloud Functions client for vendor partner auth.
class PartnerAuthApi {
  PartnerAuthApi({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: _region,
            );

  static const _region = 'us-central1';
  static const _role = 'vendor';

  final FirebaseFunctions _fn;

  HttpsCallable _callable(String name) => _fn.httpsCallable(name);

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Never _handleError(Object e, {String context = 'request'}) {
    if (e is FirebaseFunctionsException) {
      VendorAuthErrors.logDebug(
        'callable=$context code=${e.code} message=${e.message}',
      );
      throw VendorAuthException(
        VendorAuthErrors.fromFunctionsException(e),
      );
    }
    VendorAuthErrors.logDebug('callable=$context error=$e');
    throw VendorAuthException(VendorAuthErrors.fromException(e));
  }

  Map<String, dynamic> _deviceInfo() => {
        'platform': Platform.operatingSystem,
        'deviceId': Platform.localHostname,
        'appVersion': '1.0.0',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      VendorAuthErrors.logDebug('partnerLogin email=${email.trim().toLowerCase()}');
      final res = await _callable('partnerLogin').call({
        'role': _role,
        'email': email.trim().toLowerCase(),
        'password': password,
        'deviceInfo': _deviceInfo(),
      });
      return _map(res.data);
    } catch (e) {
      _handleError(e, context: 'partnerLogin');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _callable('partnerRequestPasswordReset').call({
        'role': _role,
        'email': email.trim().toLowerCase(),
      });
    } catch (e) {
      _handleError(e, context: 'partnerRequestPasswordReset');
    }
  }

  Future<void> verifyResetOtp(String email, String otp) async {
    try {
      await _callable('partnerVerifyResetOtp').call({
        'role': _role,
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      });
    } catch (e) {
      _handleError(e, context: 'partnerVerifyResetOtp');
    }
  }

  Future<void> completePasswordReset(String email, String newPassword) async {
    try {
      await _callable('partnerCompletePasswordReset').call({
        'role': _role,
        'email': email.trim().toLowerCase(),
        'newPassword': newPassword,
      });
    } catch (e) {
      _handleError(e, context: 'partnerCompletePasswordReset');
    }
  }

  Future<int> updatePassword({
    required String partnerId,
    required String newPassword,
    String? currentPassword,
  }) async {
    try {
      final res = await _callable('partnerUpdatePassword').call({
        'role': _role,
        'partnerId': partnerId,
        'newPassword': newPassword,
        if (currentPassword != null) 'currentPassword': currentPassword,
      });
      final data = _map(res.data);
      return (data['sessionVersion'] as num?)?.toInt() ?? 0;
    } catch (e) {
      _handleError(e, context: 'partnerUpdatePassword');
    }
  }

  Future<Map<String, dynamic>> checkSession({
    required String partnerId,
    required int sessionVersion,
  }) async {
    try {
      final res = await _callable('partnerCheckSession').call({
        'role': _role,
        'partnerId': partnerId,
        'sessionVersion': sessionVersion,
      });
      return _map(res.data);
    } catch (e) {
      _handleError(e, context: 'partnerCheckSession');
    }
  }
}
