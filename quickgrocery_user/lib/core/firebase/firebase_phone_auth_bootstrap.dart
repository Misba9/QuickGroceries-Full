import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/firebase/phone_auth_verification_path.dart';

/// Phone Auth verification settings (Android + iOS).
///
/// Lightweight by default — [logDiagnostics] is opt-in (debug diagnostic
/// screen / explicit call). Never dumps the full config audit on cold start.
Future<void> configureFirebasePhoneAuth({
  bool logDiagnostics = false,
}) async {
  if (kIsWeb) return;

  await FirebaseAuth.instance.setSettings(
    forceRecaptchaFlow: false,
  );

  if (logDiagnostics && kDebugMode) {
    FirebasePhoneAuthLogger.info(
      'PhoneAuth setSettings forceRecaptchaFlow=false '
      'kDebugMode=$kDebugMode',
    );
    await PhoneAuthVerificationPath.logSelectedPath(phase: 'explicit_diag');
  }
}
