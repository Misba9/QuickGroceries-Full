import 'package:flutter/foundation.dart';

/// Firebase Console → App Check → enforcement for Authentication.
///
/// When `false`, App Check tokens are not enforced by Firebase backends, but
/// the SDK provider is still activated so Phone Auth does not attach placeholder
/// tokens ("No AppCheckProvider installed").
const bool kFirebaseAppCheckEnforced = false;

/// Which App Check attestation provider to use per Flutter build mode.
///
/// | Mode    | Android            | Apple                              |
/// |---------|--------------------|------------------------------------|
/// | debug   | debug              | debug                              |
/// | profile | debug              | debug                              |
/// | release | Play Integrity     | App Attest + DeviceCheck fallback  |
///
/// Debug providers are **never** used in release builds (store or local).
bool get usePlayIntegrityAppCheck => kReleaseMode;

bool get useAppAttestAppCheck => kReleaseMode;

/// Human-readable label for logs.
String get appCheckAndroidProviderLabel =>
    usePlayIntegrityAppCheck ? 'playIntegrity' : 'debug';

String get appCheckAppleProviderLabel =>
    useAppAttestAppCheck ? 'appAttestWithDeviceCheckFallback' : 'debug';
