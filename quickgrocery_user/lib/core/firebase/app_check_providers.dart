import 'package:flutter/foundation.dart';

/// Firebase Console → App Check → enforcement for Authentication.
///
/// When `false`, App Check tokens are not enforced by Firebase backends, but
/// the SDK provider is still activated so Phone Auth does not attach placeholder
/// tokens ("No AppCheckProvider installed").
const bool kFirebaseAppCheckEnforced = false;

/// Which App Check attestation provider to use per Flutter build mode.
///
/// | Mode    | Dart define              | Provider (Android / Apple)              |
/// |---------|--------------------------|-----------------------------------------|
/// | debug   | (default)                | debug / debug                           |
/// | profile | (default)                | debug / debug                           |
/// | release | (default)                | debug / debug                           |
/// | release | `PLAY_STORE_RELEASE=true`| playIntegrity / (Apple still needs below)|
/// | release | `APP_STORE_RELEASE=true` | playIntegrity* / appAttest+DeviceCheck  |
///
/// \* Android Play Integrity still requires `PLAY_STORE_RELEASE=true`.
///
/// Sideloaded release builds cannot pass store attestation. Enable only for
/// store-signed builds:
/// - Android: `flutter build appbundle --dart-define=PLAY_STORE_RELEASE=true`
/// - iOS: `flutter build ipa --dart-define=APP_STORE_RELEASE=true`
bool get usePlayIntegrityAppCheck =>
    kReleaseMode &&
    !kDebugMode &&
    !kProfileMode &&
    const bool.fromEnvironment('PLAY_STORE_RELEASE', defaultValue: false);

bool get useAppAttestAppCheck =>
    kReleaseMode &&
    !kDebugMode &&
    !kProfileMode &&
    const bool.fromEnvironment('APP_STORE_RELEASE', defaultValue: false);

/// Human-readable label for logs.
String get appCheckAndroidProviderLabel =>
    usePlayIntegrityAppCheck ? 'playIntegrity' : 'debug';

String get appCheckAppleProviderLabel =>
    useAppAttestAppCheck ? 'appAttestWithDeviceCheckFallback' : 'debug';
