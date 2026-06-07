import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';

/// Android Phone Auth verification settings (Play Integrity vs reCAPTCHA).
///
/// [forceRecaptchaFlow] skips Play Integrity (which fails when Play Console
/// links a different GCP project than Firebase, or when oauth_client is empty
/// in google-services.json) and uses the Android API key + reCAPTCHA path.
Future<void> configureFirebasePhoneAuth() async {
  if (kIsWeb) return;

  await FirebaseAuth.instance.setSettings(
    forceRecaptchaFlow: true,
  );
  FirebasePhoneAuthLogger.info(
    'PhoneAuth setSettings forceRecaptchaFlow=true '
    'package=com.quickgrocery.io appId=db7a0d4e8b73454f6e0c70 '
    'kDebugMode=$kDebugMode kProfileMode=$kProfileMode kReleaseMode=$kReleaseMode',
  );
}
