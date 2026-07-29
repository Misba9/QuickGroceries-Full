import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/firebase/google_services_parser.dart';

/// How Firebase will verify the app before sending an SMS OTP.
enum PhoneAuthVerificationMethod {
  /// Play Integrity / SafetyNet when SHA is registered in Firebase Console.
  nativePlayIntegrity,

  /// iOS silent APNs push when APNs key is uploaded and entitlements are correct.
  silentApns,

  /// Browser reCAPTCHA when native attestation is unavailable.
  webRecaptchaFallback,
}

/// Logs the expected verification path. Does **not** block login solely because
/// bundled google-services.json has empty oauth_client — that file is often
/// stale even after SHA is registered (Phone Auth still works via Play Integrity).
abstract final class PhoneAuthVerificationPath {
  static Future<void> logSelectedPath({required String phase}) async {
    final method = await resolveMethod();
    final gs = await GoogleServicesConfig.loadFromAssets();
    final client = gs?.clientForPackage(
      FirebaseConfigAudit.expectedAndroidPackage,
    );
    FirebasePhoneAuthLogger.info(
      '$phase verification_method=${method.logLabel} '
      'oauth_client_count=${client?.oauthClientCount ?? -1}',
    );
    if (client != null && client.oauthClientCount == 0) {
      FirebasePhoneAuthLogger.warn(
        '$phase oauth_client empty in bundled google-services.json — '
        'informational only; proceed if SHA is in Firebase Console',
      );
    }
  }

  /// Never block solely on empty oauth_client in google-services.json.
  static Future<String?> blockingMisconfigurationError() async {
    if (kIsWeb) return null;

    final report = await FirebaseConfigAudit.runAudit();
    for (final issue in report.criticalIssues) {
      // Wrong app id / package is a real blocker; empty oauth_client is not.
      if (issue.id == 'missing-sha-oauth-client') continue;
      if (issue.id == 'google-services-wrong-app-id' ||
          issue.id == 'android-package-mismatch' ||
          issue.id == 'android-app-id-mismatch' ||
          issue.id == 'firebase-not-initialized') {
        return '${issue.title}\n\n${issue.fixSteps.first}';
      }
    }
    return null;
  }

  static Future<PhoneAuthVerificationMethod> resolveMethod() async {
    if (kIsWeb) {
      return PhoneAuthVerificationMethod.webRecaptchaFallback;
    }
    if (Platform.isIOS) {
      // Expected path when APNs key + Push + Background Modes are configured.
      // If any of those fail at runtime, Firebase silently falls back to Safari.
      return PhoneAuthVerificationMethod.silentApns;
    }
    if (!Platform.isAndroid) {
      return PhoneAuthVerificationMethod.webRecaptchaFallback;
    }

    final gs = await GoogleServicesConfig.loadFromAssets();
    final client = gs?.clientForPackage(
      FirebaseConfigAudit.expectedAndroidPackage,
    );

    if (client != null && client.hasAndroidOAuthClient) {
      return PhoneAuthVerificationMethod.nativePlayIntegrity;
    }

    // oauth_client empty but SHA may still be registered in Firebase Console.
    return PhoneAuthVerificationMethod.nativePlayIntegrity;
  }
}

extension _PhoneAuthVerificationMethodLog on PhoneAuthVerificationMethod {
  String get logLabel => switch (this) {
        PhoneAuthVerificationMethod.nativePlayIntegrity =>
          'native_play_integrity',
        PhoneAuthVerificationMethod.silentApns => 'silent_apns',
        PhoneAuthVerificationMethod.webRecaptchaFallback =>
          'web_recaptcha_fallback',
      };
}
