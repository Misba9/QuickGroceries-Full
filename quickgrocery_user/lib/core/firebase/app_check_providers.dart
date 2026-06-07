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
/// Play Integrity only works for Play Store / properly attested release
/// builds. Profile and debug APKs must use [usePlayIntegrityAppCheck] = false.
bool get usePlayIntegrityAppCheck => kReleaseMode && !kProfileMode && !kDebugMode;

/// Human-readable label for logs.
String get appCheckAndroidProviderLabel =>
    usePlayIntegrityAppCheck ? 'playIntegrity' : 'debug';
