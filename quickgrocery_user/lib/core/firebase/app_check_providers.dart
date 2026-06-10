import 'package:flutter/foundation.dart';

/// Firebase Console → App Check → enforcement for Authentication.
///
/// When `false`, App Check tokens are not enforced by Firebase backends, but
/// the SDK provider is still activated so Phone Auth does not attach placeholder
/// tokens ("No AppCheckProvider installed").
const bool kFirebaseAppCheckEnforced = false;

/// Which App Check attestation provider to use per Flutter build mode.
///
/// | Mode    | kDebugMode | kProfileMode | kReleaseMode | Provider        |
/// |---------|------------|--------------|--------------|-----------------|
/// | debug   | true       | false        | false        | debug           |
/// | profile | false      | true         | true         | debug           |
/// | release | false      | false        | true         | playIntegrity   |
///
/// Sideloaded release builds (`flutter run --release`, USB APK) are signed with
/// the debug keystore unless key.properties exists — they cannot pass Play
/// Integrity. Only enable for Play Store app bundles:
/// `flutter build appbundle --dart-define=PLAY_STORE_RELEASE=true`
bool get usePlayIntegrityAppCheck =>
    kReleaseMode &&
    !kDebugMode &&
    !kProfileMode &&
    const bool.fromEnvironment('PLAY_STORE_RELEASE', defaultValue: false);

/// Human-readable label for logs.
String get appCheckAndroidProviderLabel =>
    usePlayIntegrityAppCheck ? 'playIntegrity' : 'debug';
