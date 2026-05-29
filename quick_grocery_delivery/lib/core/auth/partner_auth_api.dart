import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quick_grocery_delivery/core/firebase/callable_payload.dart';

class PartnerAuthApi {
  PartnerAuthApi({FirebaseFunctions? functions})
    : _fn =
          functions ??
          FirebaseFunctions.instanceFor(app: Firebase.app(), region: _region);

  static const _region = 'us-central1';
  static const _role = 'delivery';

  final FirebaseFunctions _fn;

  HttpsCallable _callable(String name) => _fn.httpsCallable(name);

  Future<HttpsCallableResult<dynamic>> _callJson(
    String name,
    Map<String, dynamic> payload,
  ) {
    final safePayload = sanitizeCallableData(payload);
    debugCallableData(name, safePayload);
    return _callable(name).call(safePayload);
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Never _handleError(Object e) {
    if (e is FirebaseFunctionsException) {
      throw Exception(e.message ?? 'Request failed');
    }
    throw Exception(e.toString());
  }

  Map<String, dynamic> _deviceInfo() => {
    'platform': Platform.operatingSystem,
    'deviceId': Platform.localHostname,
    'appVersion': '1.0.1',
  };

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _callJson('partnerLogin', {
        'role': _role,
        'email': email.trim().toLowerCase(),
        'password': password,
        'deviceInfo': _deviceInfo(),
      });
      return _map(res.data);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _callJson('partnerRequestPasswordReset', {
        'role': _role,
        'email': email.trim().toLowerCase(),
      });
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> verifyResetOtp(String email, String otp) async {
    try {
      await _callJson('partnerVerifyResetOtp', {
        'role': _role,
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      });
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> completePasswordReset(String email, String newPassword) async {
    try {
      await _callJson('partnerCompletePasswordReset', {
        'role': _role,
        'email': email.trim().toLowerCase(),
        'newPassword': newPassword,
      });
    } catch (e) {
      _handleError(e);
    }
  }

  Future<int> updatePassword({
    required String partnerId,
    required String newPassword,
    String? currentPassword,
  }) async {
    try {
      final res = await _callJson('partnerUpdatePassword', {
        'role': _role,
        'partnerId': partnerId,
        'newPassword': newPassword,
        if (currentPassword != null) 'currentPassword': currentPassword,
      });
      final data = _map(res.data);
      return (data['sessionVersion'] as num?)?.toInt() ?? 0;
    } catch (e) {
      _handleError(e);
    }
  }

  Future<Map<String, dynamic>> checkSession({
    required String partnerId,
    required int sessionVersion,
  }) async {
    try {
      final res = await _callJson('partnerCheckSession', {
        'role': _role,
        'partnerId': partnerId,
        'sessionVersion': sessionVersion,
      });
      return _map(res.data);
    } catch (e) {
      _handleError(e);
    }
  }
}
