import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/app_check_providers.dart';
import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';

/// Pre-flight checks before Firebase Phone Auth (especially iOS).
class FirebaseAuthReadiness {
  /// Returns a user-facing error message, or `null` when ready.
  ///
  /// Does NOT block on empty [oauth_client] in bundled google-services.json —
  /// that field is often stale even when SHA is registered in Firebase Console.
  static Future<String?> ensurePhoneAuthReady() async {
    if (Firebase.apps.isEmpty) {
      return 'Firebase is still starting. Please wait a moment and try again.';
    }

    if (kIsWeb) return null;

    final options = Firebase.app().options;
    final packageInfo = await PackageInfo.fromPlatform();
    final appCheckProvider = appCheckAndroidProviderLabel;

    FirebasePhoneAuthLogger.logRuntimeContext(
      phase: 'ensurePhoneAuthReady',
      firebaseAppName: Firebase.app().name,
      packageName: packageInfo.packageName,
      projectId: options.projectId,
      appId: options.appId,
      appCheckProvider: appCheckProvider,
    );

    final report = await FirebaseConfigAudit.runAudit();
    FirebasePhoneAuthLogger.info(report.toDebugString());

    // Empty oauth_client in the bundled JSON is often stale even when SHA
    // fingerprints are registered in Firebase Console — do not block here;
    // let verifyPhoneNumber() run and surface a real Firebase error if needed.
    if (report.issues.any((i) => i.id == 'missing-sha-oauth-client')) {
      FirebasePhoneAuthLogger.warn(
        'google-services.json oauth_client is empty — proceeding anyway '
        '(SHA may already be registered in Firebase Console).',
      );
    }

    if (!report.isReadyForPhoneAuth) {
      final summary = report.toUserFacingSummary();
      if (summary.isNotEmpty) {
        FirebasePhoneAuthLogger.warn('ensurePhoneAuthReady blocked: $summary');
        return summary;
      }
    }

    FirebasePhoneAuthLogger.info(
      'ensurePhoneAuthReady PASS — proceeding to verifyPhoneNumber()',
    );
    return null;
  }

  /// Normalizes Indian mobile input to E.164 (+91XXXXXXXXXX).
  static String? normalizePhoneNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return null;

    if (trimmed.startsWith('+')) {
      final normalized = '+$digitsOnly';
      if (normalized.length < 11) return null;
      return normalized;
    }

    if (digitsOnly.length == 10) {
      return '+91$digitsOnly';
    }

    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }

    return null;
  }

  static void log(String message) => FirebasePhoneAuthLogger.info(message);
}
