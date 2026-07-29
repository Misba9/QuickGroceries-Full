import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/firebase/phone_auth_verification_path.dart';

/// Phone Auth verification settings (Android + iOS).
///
/// **Android native path (Play Integrity / SafetyNet):** default when
/// [forceRecaptchaFlow] is false. Requires SHA-1/SHA-256 in Firebase Console.
///
/// **iOS silent APNs path:** default when Push Notifications + Background Modes
/// (remote-notification) are enabled, APNs token is passed to Auth, and an
/// APNs Auth Key (.p8) is uploaded under Firebase → Cloud Messaging.
///
/// **Web reCAPTCHA / Safari fallback:** used when native attestation cannot run
/// (missing SHA, no APNs key, Simulator, Background App Refresh off, etc.).
///
/// Do NOT force reCAPTCHA — that disables the native path and always opens the
/// browser verification page when native checks fail.
Future<void> configureFirebasePhoneAuth() async {
  if (kIsWeb) return;

  await FirebaseAuth.instance.setSettings(
    forceRecaptchaFlow: false,
  );
  FirebasePhoneAuthLogger.info(
    'PhoneAuth setSettings forceRecaptchaFlow=false '
    '(Android: Play Integrity / iOS: silent APNs when configured) '
    'kDebugMode=$kDebugMode kReleaseMode=$kReleaseMode',
  );
  await PhoneAuthVerificationPath.logSelectedPath(phase: 'app_startup');
}
