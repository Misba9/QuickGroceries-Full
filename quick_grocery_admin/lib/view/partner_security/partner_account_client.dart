import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Admin Cloud Functions for vendor / delivery account security.
class PartnerAccountClient {
  PartnerAccountClient({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: _region,
            );

  static const _region = 'us-central1';

  final FirebaseFunctions _fn;

  Future<void> _ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Sign in to the admin panel first.');
    }
  }

  Future<Map<String, dynamic>> _call(
    String action, {
    required String role,
    required String partnerId,
    Map<String, dynamic> extra = const {},
  }) async {
    await _ensureSignedIn();
    final res = await _fn.httpsCallable('adminPartnerAccountAction').call({
      'role': role,
      'partnerId': partnerId,
      'action': action,
      ...extra,
    });
    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {'success': true};
  }

  Future<String> resetPasswordManual({
    required String role,
    required String partnerId,
    required String newPassword,
  }) async {
    final r = await _call(
      'reset_password_manual',
      role: role,
      partnerId: partnerId,
      extra: {'newPassword': newPassword},
    );
    return r['message']?.toString() ?? 'Password updated.';
  }

  Future<String> sendPasswordResetEmail({
    required String role,
    required String partnerId,
  }) async {
    final r = await _call(
      'send_password_reset_email',
      role: role,
      partnerId: partnerId,
    );
    return r['message']?.toString() ?? 'Email sent.';
  }

  Future<String> forceLogout({
    required String role,
    required String partnerId,
  }) async {
    final r = await _call(
      'force_logout',
      role: role,
      partnerId: partnerId,
    );
    return r['message']?.toString() ?? 'User logged out.';
  }

  Future<String> setEnabled({
    required String role,
    required String partnerId,
    required bool enabled,
  }) async {
    final r = await _call(
      'set_enabled',
      role: role,
      partnerId: partnerId,
      extra: {'enabled': enabled},
    );
    return r['message']?.toString() ?? (enabled ? 'Enabled' : 'Disabled');
  }

  Future<String> setForcePasswordChange({
    required String role,
    required String partnerId,
    required bool force,
  }) async {
    final r = await _call(
      'set_force_password_change',
      role: role,
      partnerId: partnerId,
      extra: {'force': force},
    );
    return r['message']?.toString() ?? 'Updated.';
  }
}
