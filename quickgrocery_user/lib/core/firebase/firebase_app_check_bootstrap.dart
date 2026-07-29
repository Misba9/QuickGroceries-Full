import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/app_check_providers.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';

/// Activates Firebase App Check with environment-appropriate providers.
///
/// - Debug / profile: debug providers (register tokens in Firebase Console
///   if enforcement is enabled).
/// - Release: Play Integrity (Android) / App Attest+DeviceCheck (iOS).
///   Never activates the debug provider in release builds.
Future<void> configureFirebaseAppCheck() async {
  if (kIsWeb) return;

  final androidLabel = appCheckAndroidProviderLabel;
  final appleLabel = appCheckAppleProviderLabel;

  FirebasePhoneAuthLogger.info(
    'AppCheck activating android=$androidLabel apple=$appleLabel '
    'kDebugMode=$kDebugMode kProfileMode=$kProfileMode kReleaseMode=$kReleaseMode',
  );

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: usePlayIntegrityAppCheck
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: useAppAttestAppCheck
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
