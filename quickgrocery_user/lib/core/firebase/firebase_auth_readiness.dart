import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';

/// Pre-flight checks before Firebase Phone Auth (especially iOS).
class FirebaseAuthReadiness {
  /// Returns a user-facing error message, or `null` when ready.
  static Future<String?> ensurePhoneAuthReady() async {
    if (Firebase.apps.isEmpty) {
      return 'Firebase is still starting. Please wait a moment and try again.';
    }

    if (kIsWeb) return null;

    final options = Firebase.app().options;
    final packageInfo = await PackageInfo.fromPlatform();

    log(
      'config package=${packageInfo.packageName} '
      'projectId=${options.projectId} appId=${options.appId}',
    );

    final report = await FirebaseConfigAudit.runAudit();
    log(report.toDebugString());
    if (!report.isReadyForPhoneAuth) {
      return report.toUserFacingSummary();
    }
    if (report.issues.any((i) => i.id == 'missing-sha-oauth-client')) {
      log(
        'WARN: oauth_client empty — Phone Auth may fail until SHA creates '
        'OAuth client in Firebase.',
      );
    }

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

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[PhoneAuth] $message');
    }
  }
}
