import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// HTTPS callable bridge — secrets stay in Cloud Functions only.
class SmsFunctionsClient {
  SmsFunctionsClient({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: _defaultRegion);

  static const _defaultRegion = 'us-central1';

  final FirebaseFunctions _fn;

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('You must be signed in to send SMS.');
    }
  }

  Future<Map<String, dynamic>> sendSingleSMS({
    required String phone,
    required String message,
    String? userId,
    String? title,
  }) async {
    await _ensureSignedIn();
    final callable = _fn.httpsCallable('sendSingleSMS');
    final res = await callable.call(<String, dynamic>{
      'phone': phone,
      'message': message,
      if (userId != null) 'userId': userId,
      if (title != null) 'title': title,
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> enqueueBroadcastSMS({
    required String title,
    required String message,
    required String targetType,
    DateTime? scheduledAt,
  }) async {
    await _ensureSignedIn();
    final callable = _fn.httpsCallable('enqueueBroadcastSMS');
    final res = await callable.call(<String, dynamic>{
      'title': title,
      'message': message,
      'targetType': targetType,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> scheduleSMS({
    required String title,
    required String message,
    required String targetType,
    required DateTime scheduledAt,
  }) async {
    await _ensureSignedIn();
    final callable = _fn.httpsCallable('scheduleSMS');
    final res = await callable.call(<String, dynamic>{
      'title': title,
      'message': message,
      'targetType': targetType,
      'scheduledAt': scheduledAt.toIso8601String(),
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> resumeBroadcastSMS({
    required String campaignId,
  }) async {
    await _ensureSignedIn();
    final callable = _fn.httpsCallable('resumeBroadcastSMS');
    final res = await callable.call(<String, dynamic>{
      'campaignId': campaignId,
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> retryFailedSMS({int max = 25}) async {
    await _ensureSignedIn();
    try {
      final callable = _fn.httpsCallable('retryFailedSMS');
      final res = await callable.call(<String, dynamic>{'max': max});
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'ok': true};
    } catch (e) {
      if (kDebugMode) debugPrint('[SmsFunctionsClient] retryFailedSMS: $e');
      rethrow;
    }
  }

  /// Grant `admin` + `smsAdmin` + `role: admin` (server-side). See Cloud Function rules.
  Future<Map<String, dynamic>> syncAdminClaimsFromAdmins() async {
    await _ensureSignedIn();
    final callable = _fn.httpsCallable('syncAdminClaimsFromAdmins');
    final res = await callable.call();
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }

  Future<Map<String, dynamic>> setAdminClaims({
    String? uid,
    String? bootstrapSecret,
  }) async {
    await _ensureSignedIn();
    final callable = _fn.httpsCallable('setAdminClaims');
    final res = await callable.call(<String, dynamic>{
      if (uid != null && uid.isNotEmpty) 'uid': uid,
      if (bootstrapSecret != null && bootstrapSecret.isNotEmpty)
        'bootstrapSecret': bootstrapSecret,
    });
    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {'ok': true};
  }
}
