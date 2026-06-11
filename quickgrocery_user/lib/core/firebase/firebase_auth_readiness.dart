import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/app_check_providers.dart';
import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/firebase/phone_auth_verification_path.dart';

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

    await PhoneAuthVerificationPath.logSelectedPath(
      phase: 'ensurePhoneAuthReady',
    );

    final configBlock = await PhoneAuthVerificationPath.blockingMisconfigurationError();
    if (configBlock != null) {
      FirebasePhoneAuthLogger.error(
        'ensurePhoneAuthReady BLOCKED — $configBlock',
      );
      return configBlock;
    }

    if (report.issues.any((i) => i.id == 'missing-sha-oauth-client')) {
      FirebasePhoneAuthLogger.warn(
        'oauthClientCount=0 in bundled google-services.json — '
        'informational only, not blocking verifyPhoneNumber()',
      );
    }

    if (!report.isReadyForPhoneAuth) {
      FirebasePhoneAuthLogger.warn(
        'ensurePhoneAuthReady audit issues (non-blocking): '
        '${report.toUserFacingSummary()}',
      );
    } else {
      FirebasePhoneAuthLogger.info(
        'ensurePhoneAuthReady audit PASS',
      );
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
