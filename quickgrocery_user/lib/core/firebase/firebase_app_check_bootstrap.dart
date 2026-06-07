import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/app_check_providers.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';

/// Activates Firebase App Check with environment-appropriate providers.
///
/// Debug / profile: [AndroidProvider.debug] — register debug token in Firebase
/// Console → App Check → Manage debug tokens (if enforcement is enabled).
///
/// Release: [AndroidProvider.playIntegrity] — requires Play Store signing +
/// Play Integrity API enabled in Google Cloud.
Future<void> configureFirebaseAppCheck() async {
  if (kIsWeb) return;

  final androidLabel = appCheckAndroidProviderLabel;
  final appleLabel = usePlayIntegrityAppCheck
      ? 'appAttestWithDeviceCheckFallback'
      : 'debug';

  FirebasePhoneAuthLogger.info(
    'AppCheck activating android=$androidLabel apple=$appleLabel '
    'kDebugMode=$kDebugMode kProfileMode=$kProfileMode kReleaseMode=$kReleaseMode',
  );

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: usePlayIntegrityAppCheck
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: usePlayIntegrityAppCheck
          ? AppleProvider.appAttestWithDeviceCheckFallback
          : AppleProvider.debug,
    );

  } catch (e, st) {
    FirebasePhoneAuthLogger.error(
      'AppCheck activation failed: $e',
      error: e,
      stackTrace: st,
    );
  }
}
