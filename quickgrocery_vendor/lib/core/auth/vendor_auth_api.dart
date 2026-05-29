import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:quickgrocery_vendor/core/firebase/callable_payload.dart';

/// Vendor-facing auth helpers (public callables).
class VendorAuthApi {
  VendorAuthApi({FirebaseFunctions? functions})
    : _fn =
          functions ??
          FirebaseFunctions.instanceFor(app: Firebase.app(), region: _region);

  static const _region = 'us-central1';

  final FirebaseFunctions _fn;

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> checkAuthForPasswordReset(String email) async {
    final payload = sanitizeCallableData({'email': email.trim().toLowerCase()});
    debugCallableData('vendorCheckAuthForPasswordReset', payload);
    final res = await _fn
        .httpsCallable('vendorCheckAuthForPasswordReset')
        .call(payload);
    final map = _map(res.data);
    if (kDebugMode) {
      debugPrint('[VendorAuthApi] reset check: $map');
    }
    return map;
  }

  Future<Map<String, dynamic>> diagnoseLogin(String email) async {
    final payload = sanitizeCallableData({'email': email.trim().toLowerCase()});
    debugCallableData('vendorDiagnoseLogin', payload);
    final res = await _fn.httpsCallable('vendorDiagnoseLogin').call(payload);
    final map = _map(res.data);
    if (kDebugMode) {
      debugPrint('[VendorAuthApi] login diagnose: $map');
    }
    return map;
  }
}
