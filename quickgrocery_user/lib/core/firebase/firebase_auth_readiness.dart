import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Pre-flight checks before Firebase Phone Auth (especially iOS).
class FirebaseAuthReadiness {
  static const _placeholderAppIdSuffix = '0000000000000000000000';

  /// Returns a user-facing error message, or `null` when ready.
  static Future<String?> ensurePhoneAuthReady() async {
    if (Firebase.apps.isEmpty) {
      return 'Firebase is still starting. Please wait a moment and try again.';
    }

    if (kIsWeb) return null;

    if (Platform.isIOS) {
      final options = Firebase.app().options;
      final appId = options.appId;

      if (appId.contains(_placeholderAppIdSuffix) ||
          appId.contains('REPLACE_WITH')) {
        return 'iOS Firebase is not configured yet.\n\n'
            '1. Open Firebase Console → project "quikgroceries"\n'
            '2. Add iOS app with bundle ID: com.ahmed.quickgrocery\n'
            '3. Download GoogleService-Info.plist\n'
            '4. Replace ios/Runner/GoogleService-Info.plist\n'
            '5. Copy REVERSED_CLIENT_ID from that file into ios/Runner/Info.plist '
            '(CFBundleURLSchemes)\n'
            '6. Run: flutter clean && flutter run\n\n'
            'Or run: dart pub global activate flutterfire_cli && flutterfire configure';
      }

      if (options.apiKey.isEmpty || options.projectId.isEmpty) {
        return 'Firebase iOS options are incomplete. Run '
            'flutterfire configure for project quikgroceries.';
      }
    }

    return null;
  }

  /// Normalizes Indian mobile input to E.164 (+91XXXXXXXXXX).
  static String? normalizePhoneNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return null;

    if (trimmed.startsWith('+')) {
      final normalized = '+$digitsOnly';
      if (normalized.length < 11) return null;
      return normalized;
    }

    if (digitsOnly.length == 10) {
      return '+91$digitsOnly';
    }

    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return '+$digitsOnly';
    }

    return null;
  }

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[PhoneAuth] $message');
    }
  }
}
