import 'package:flutter/foundation.dart';

/// Firebase Console → Authentication → Phone → "Phone numbers for testing".
///
/// Only consulted in **debug** builds. Release builds never treat any number
/// as a test number (no special-casing, no hardcoded OTPs in production).
abstract final class PhoneAuthDebugTestNumbers {
  /// Optional local map of E.164 → OTP for documentation / tooling.
  /// Prefer configuring test numbers in Firebase Console; the SDK handles them.
  static const Map<String, String> consoleConfigured = <String, String>{
    // Example (uncomment only for local debug against Console test numbers):
    // '+911234567890': '123456',
  };

  static bool isTestNumber(String e164) {
    if (!kDebugMode) return false;
    return consoleConfigured.containsKey(e164);
  }

  static String? debugOtpFor(String e164) {
    if (!kDebugMode) return null;
    return consoleConfigured[e164];
  }
}
