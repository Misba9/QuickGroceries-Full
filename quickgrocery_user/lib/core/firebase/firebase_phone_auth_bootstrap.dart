import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';

/// Android Phone Auth verification settings.
///
/// **Native path (Play Integrity / SafetyNet):** default when
/// [forceRecaptchaFlow] is false. Requires SHA-1/SHA-256 registered in Firebase
/// Console and a valid `oauth_client` in google-services.json.
///
/// **Web reCAPTCHA fallback:** Firebase opens only when native attestation
/// cannot run (missing SHA, sideloaded release APK, emulator, etc.).
///
/// Do NOT force reCAPTCHA — that disables Play Integrity and always shows the
/// browser verification page when native checks fail.
Future<void> configureFirebasePhoneAuth() async {
  if (kIsWeb) return;

  await FirebaseAuth.instance.setSettings(
    forceRecaptchaFlow: false,
  );
  FirebasePhoneAuthLogger.info(
    'PhoneAuth setSettings forceRecaptchaFlow=false (native Play Integrity when SHA configured) '
    'kDebugMode=$kDebugMode kReleaseMode=$kReleaseMode',
  );
}
