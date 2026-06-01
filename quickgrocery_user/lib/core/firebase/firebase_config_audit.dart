import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/firebase_options.dart';

/// A single misconfiguration detected during Firebase Phone Auth audit.
class FirebaseConfigIssue {
  const FirebaseConfigIssue({
    required this.id,
    required this.title,
    required this.detail,
    required this.fixSteps,
    this.severity = 'critical',
  });

  final String id;
  final String title;
  final String detail;
  final List<String> fixSteps;
  final String severity;
}

/// Runtime audit result for Firebase Phone Authentication setup.
class PhoneAuthConfigReport {
  PhoneAuthConfigReport({
    required this.platform,
    required this.packageName,
    required this.projectId,
    required this.appId,
    required this.apiKeyPrefix,
    required this.issues,
    required this.passedChecks,
    this.googleServicesOAuthClientCount,
    this.googleServicesAppId,
    this.isDebugBuild = kDebugMode,
  });

  final String platform;
  final String packageName;
  final String projectId;
  final String appId;
  final String apiKeyPrefix;
  final List<FirebaseConfigIssue> issues;
  final List<String> passedChecks;
  final int? googleServicesOAuthClientCount;
  final String? googleServicesAppId;
  final bool isDebugBuild;

  bool get isReadyForPhoneAuth =>
      !issues.any((issue) => issue.severity == 'critical');

  List<FirebaseConfigIssue> get criticalIssues =>
      issues.where((i) => i.severity == 'critical').toList();

  String toDebugString() {
    final buffer = StringBuffer()
      ..writeln('=== Firebase Phone Auth Config Report ===')
      ..writeln('platform: $platform')
      ..writeln('package/bundle: $packageName')
      ..writeln('projectId: $projectId')
      ..writeln('appId: $appId')
      ..writeln('apiKey: $apiKeyPrefix…')
      ..writeln('build: ${isDebugBuild ? 'debug' : 'release'}');
    if (googleServicesAppId != null) {
      buffer.writeln('google-services appId: $googleServicesAppId');
    }
    if (googleServicesOAuthClientCount != null) {
      buffer.writeln(
        'google-services oauth_client count: $googleServicesOAuthClientCount',
      );
    }
    if (passedChecks.isNotEmpty) {
      buffer.writeln('\nPassed (${passedChecks.length}):');
      for (final check in passedChecks) {
        buffer.writeln('  ✓ $check');
      }
    }
    if (issues.isEmpty) {
      buffer.writeln('\nNo configuration issues detected.');
    } else {
      buffer.writeln('\nIssues (${issues.length}):');
      for (final issue in issues) {
        buffer
          ..writeln('  [${issue.severity.toUpperCase()}] ${issue.title}')
          ..writeln('    ${issue.detail}');
        for (final step in issue.fixSteps) {
          buffer.writeln('    → $step');
        }
      }
    }
    buffer.writeln('=========================================');
    return buffer.toString();
  }

  String toUserFacingSummary() {
    if (isReadyForPhoneAuth) {
      return 'Firebase configuration looks correct.';
    }
    final buffer = StringBuffer('Configuration problems detected:\n');
    for (final issue in criticalIssues) {
      buffer.writeln('\n• ${issue.title}');
      buffer.writeln(issue.detail);
      if (issue.fixSteps.isNotEmpty) {
        buffer.writeln('Fix: ${issue.fixSteps.first}');
      }
    }
    return buffer.toString().trim();
  }
}

/// Audits Firebase + Android/iOS settings required for Phone Authentication.
class FirebaseConfigAudit {
  FirebaseConfigAudit._();

  static const expectedAndroidPackage = 'com.quickgrocery.io';
  static const expectedAndroidAppId =
      '1:970937777233:android:db7a0d4e8b73454f6e0c70';
  static const expectedIosBundleId = 'com.ahmed.quickgrocery';
  static const expectedProjectId = 'quikgroceries';
  static const _placeholderIosAppIdSuffix = '0000000000000000000000';

  /// SHA-1 for the default Android debug keystore on this machine.
  /// Re-register in Firebase Console if you use a different machine/keystore.
  static const debugSha1 =
      '7F:87:2A:51:EE:54:18:48:A0:5D:07:D6:8D:28:62:24:AB:7A:6C:3E';
  static const debugSha256 =
      '6F:CD:6C:DF:D7:96:79:B8:51:AB:91:FD:AF:24:71:B6:9E:EE:C2:3F:28:85:1E:93:22:6C:56:63:70:84:F1:C6';

  static const _googleServicesAsset = 'android/app/google-services.json';

  static Future<PhoneAuthConfigReport> runAudit() async {
    final issues = <FirebaseConfigIssue>[];
    final passed = <String>[];

    if (Firebase.apps.isEmpty) {
      return PhoneAuthConfigReport(
        platform: _platformLabel(),
        packageName: '(Firebase not initialized)',
        projectId: '(unknown)',
        appId: '(unknown)',
        apiKeyPrefix: '(unknown)',
        issues: const [
          FirebaseConfigIssue(
            id: 'firebase-not-initialized',
            title: 'Firebase not initialized',
            detail: 'Firebase.initializeApp() must complete before phone auth.',
            fixSteps: [
              'Ensure initializeFirebaseWithRetry() runs in main() before login.',
            ],
          ),
        ],
        passedChecks: passed,
      );
    }

    final options = Firebase.app().options;
    final packageInfo = await PackageInfo.fromPlatform();
    final installedId = packageInfo.packageName;
    final projectId = options.projectId;
    final appId = options.appId;
    final apiKeyPrefix = options.apiKey.length >= 8
        ? options.apiKey.substring(0, 8)
        : options.apiKey;

    if (projectId == expectedProjectId) {
      passed.add('projectId matches "$expectedProjectId"');
    } else {
      issues.add(
        FirebaseConfigIssue(
          id: 'project-id-mismatch',
          title: 'Wrong Firebase project',
          detail:
              'Running project "$projectId" but expected "$expectedProjectId".',
          fixSteps: [
            'Run: dart pub global activate flutterfire_cli && flutterfire configure',
            'Re-download google-services.json and GoogleService-Info.plist.',
          ],
        ),
      );
    }

    if (kIsWeb) {
      return PhoneAuthConfigReport(
        platform: 'web',
        packageName: installedId,
        projectId: projectId,
        appId: appId,
        apiKeyPrefix: apiKeyPrefix,
        issues: issues,
        passedChecks: passed,
      );
    }

    if (Platform.isAndroid) {
      _auditAndroid(
        issues: issues,
        passed: passed,
        installedId: installedId,
        appId: appId,
        options: options,
      );
    } else if (Platform.isIOS) {
      _auditIos(
        issues: issues,
        passed: passed,
        installedId: installedId,
        appId: appId,
        options: options,
      );
    }

    int? oauthCount;
    String? gsAppId;
    if (Platform.isAndroid) {
      final gs = await _parseGoogleServicesJson();
      if (gs == null) {
        issues.add(
          const FirebaseConfigIssue(
            id: 'google-services-missing',
            title: 'google-services.json not bundled for audit',
            detail:
                'Could not read android/app/google-services.json from assets.',
            fixSteps: [
              'Ensure android/app/google-services.json exists and is listed in pubspec.yaml assets.',
              'Re-download from Firebase Console → Project settings → Your apps.',
            ],
            severity: 'warning',
          ),
        );
      } else {
        final match = gs.clientsForPackage(installedId);
        if (match.isEmpty) {
          issues.add(
            FirebaseConfigIssue(
              id: 'package-not-in-google-services',
              title: 'Package name missing from google-services.json',
              detail:
                  'Installed package "$installedId" has no entry in google-services.json.',
              fixSteps: [
                'Firebase Console → quikgroceries → Project settings → Add Android app with package $expectedAndroidPackage',
                'Download fresh google-services.json → android/app/google-services.json',
                'flutter clean && flutter run',
              ],
            ),
          );
        } else if (match.length > 1) {
          final withOAuth =
              match.where((c) => c.oauthClientCount > 0).toList();
          final severity = appId != expectedAndroidAppId ? 'critical' : 'warning';
          issues.add(
            FirebaseConfigIssue(
              id: 'duplicate-firebase-android-apps',
              title: 'Duplicate Firebase Android apps for same package',
              detail:
                  'Found ${match.length} Firebase apps for "$installedId". '
                  'Runtime appId is $appId. '
                  'Use "customer new" ($expectedAndroidAppId) where SHA keys are registered.'
                  '${withOAuth.isEmpty ? ' None have oauth_client in google-services.json yet — re-download the file.' : ''}',
              fixSteps: [
                'Firebase Console → "customer new" (com.quickgrocery.io) → Download google-services.json',
                'Delete the older duplicate Android app (bd216ade…) if unused',
                'Keep appId: $expectedAndroidAppId',
              ],
              severity: severity,
            ),
          );
        }

        // Prefer the registered app + any client that already has oauth entries.
        final matchForPackage = gs.clientsForPackage(installedId);
        final primary = matchForPackage.firstWhere(
          (c) => c.appId == expectedAndroidAppId,
          orElse: () => matchForPackage.firstWhere(
            (c) => c.oauthClientCount > 0,
            orElse: () => matchForPackage.firstWhere(
              (c) => c.appId == appId,
              orElse: () => matchForPackage.first,
            ),
          ),
        );
        gsAppId = primary.appId;
        oauthCount = primary.oauthClientCount;

        if (primary.appId == expectedAndroidAppId) {
          passed.add('google-services.json appId matches firebase_options.dart');
        } else if (appId == expectedAndroidAppId) {
          issues.add(
            FirebaseConfigIssue(
              id: 'google-services-wrong-app-id',
              title: 'google-services.json points to wrong Firebase app',
              detail:
                  'Expected appId $expectedAndroidAppId ("customer new") but '
                  'google-services.json primary entry is ${primary.appId}.',
              fixSteps: [
                'Firebase Console → "customer new" → Download google-services.json',
                'Replace android/app/google-services.json',
                'flutter clean && flutter run',
              ],
            ),
          );
        }

        if (primary.oauthClientCount == 0) {
          issues.add(
            FirebaseConfigIssue(
              id: 'missing-sha-oauth-client',
              title: 'SHA-1 / SHA-256 not registered (oauth_client empty)',
              detail:
                  'google-services.json has empty oauth_client for $installedId. '
                  'Phone auth returns "missing a valid app identifier" without SHA keys.',
              fixSteps: [
                'Firebase Console → "customer new" (com.quickgrocery.io) → Download google-services.json',
                'SHA-1 should be: $debugSha1',
                'SHA-256 should be: $debugSha256',
                'Replace android/app/google-services.json (oauth_client must not be empty)',
                'flutter clean && flutter run',
              ],
            ),
          );
        } else {
          passed.add(
            'google-services.json has ${primary.oauthClientCount} oauth_client(s)',
          );
        }
      }
    }

    if (options.apiKey.isNotEmpty) {
      passed.add('apiKey is present');
    }

    return PhoneAuthConfigReport(
      platform: _platformLabel(),
      packageName: installedId,
      projectId: projectId,
      appId: appId,
      apiKeyPrefix: apiKeyPrefix,
      issues: issues,
      passedChecks: passed,
      googleServicesOAuthClientCount: oauthCount,
      googleServicesAppId: gsAppId,
    );
  }

  static void _auditAndroid({
    required List<FirebaseConfigIssue> issues,
    required List<String> passed,
    required String installedId,
    required String appId,
    required FirebaseOptions options,
  }) {
    if (installedId == expectedAndroidPackage) {
      passed.add('package name matches Firebase ($expectedAndroidPackage)');
    } else {
      issues.add(
        FirebaseConfigIssue(
          id: 'android-package-mismatch',
          title: 'Android package name mismatch',
          detail:
              'Installed package "$installedId" ≠ Firebase "$expectedAndroidPackage".',
          fixSteps: [
            'Set applicationId in android/app/build.gradle.kts to $expectedAndroidPackage, or',
            'Register "$installedId" as a new Android app in Firebase Console.',
          ],
        ),
      );
    }

    if (appId == expectedAndroidAppId) {
      passed.add('appId matches firebase_options.dart');
    } else {
      issues.add(
        FirebaseConfigIssue(
          id: 'android-app-id-mismatch',
          title: 'Firebase appId mismatch',
          detail: 'Runtime appId "$appId" ≠ expected "$expectedAndroidAppId".',
          fixSteps: [
            'Update lib/core/firebase/firebase_options.dart after flutterfire configure',
            'Ensure google-services.json mobilesdk_app_id matches.',
          ],
        ),
      );
    }

    if (kDebugMode) {
      passed.add(
        'App Check uses debug provider — register debug token in Firebase Console → App Check',
      );
    } else {
      passed.add(
        'App Check uses Play Integrity — enable Play Integrity API in Google Cloud',
      );
    }
  }

  static void _auditIos({
    required List<FirebaseConfigIssue> issues,
    required List<String> passed,
    required String installedId,
    required String appId,
    required FirebaseOptions options,
  }) {
    if (installedId == expectedIosBundleId) {
      passed.add('bundle ID matches ($expectedIosBundleId)');
    } else {
      issues.add(
        FirebaseConfigIssue(
          id: 'ios-bundle-mismatch',
          title: 'iOS bundle ID mismatch',
          detail:
              'Installed bundle "$installedId" ≠ expected "$expectedIosBundleId".',
          fixSteps: [
            'Register bundle ID in Firebase Console or update Xcode PRODUCT_BUNDLE_IDENTIFIER.',
          ],
        ),
      );
    }

    if (appId.contains(_placeholderIosAppIdSuffix) ||
        appId.contains('REPLACE_WITH')) {
      issues.add(
        FirebaseConfigIssue(
          id: 'ios-placeholder-app-id',
          title: 'iOS Firebase appId is a placeholder',
          detail: 'appId "$appId" is not a real iOS app from Firebase Console.',
          fixSteps: [
            'Firebase Console → Add iOS app (com.ahmed.quickgrocery)',
            'Download GoogleService-Info.plist → ios/Runner/',
            'Update REVERSED_CLIENT_ID in ios/Runner/Info.plist',
            'Run: flutterfire configure',
          ],
        ),
      );
    } else {
      passed.add('iOS appId is configured');
    }

    if (DefaultFirebaseOptions.iosReversedClientId.contains('REPLACE_WITH')) {
      issues.add(
        const FirebaseConfigIssue(
          id: 'ios-reversed-client-id-placeholder',
          title: 'REVERSED_CLIENT_ID not configured',
          detail:
              'Info.plist CFBundleURLSchemes must include REVERSED_CLIENT_ID from GoogleService-Info.plist.',
          fixSteps: [
            'Copy REVERSED_CLIENT_ID from GoogleService-Info.plist into Info.plist URL schemes.',
          ],
          severity: 'warning',
        ),
      );
    }
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static Future<void> logConfiguration() async {
    if (!kDebugMode) return;
    try {
      final report = await runAudit();
      debugPrint(report.toDebugString());
    } catch (e, st) {
      debugPrint('[FirebaseConfigAudit] log failed: $e\n$st');
    }
  }

  /// Full Firebase exception text for logs and UI.
  static String formatAuthException(FirebaseAuthException e) {
    final message = e.message?.trim();
    if (message == null || message.isEmpty) {
      return e.code;
    }
    return '${e.code}: $message';
  }

  /// User-facing message; appends config fix steps for known setup errors.
  static Future<String> messageForAuthException(FirebaseAuthException e) async {
    final formatted = formatAuthException(e);

    const configCodes = {
      'missing-client-identifier',
      'app-not-authorized',
      'invalid-app-credential',
      'invalid-cert-hash',
      'captcha-check-failed',
    };

    if (!configCodes.contains(e.code)) {
      return formatted;
    }

    final report = await runAudit();
    final critical = report.criticalIssues;
    if (critical.isEmpty) {
      return '$formatted\n\nIf this persists, check SHA-1/SHA-256 and App Check debug token in Firebase Console.';
    }

    final buffer = StringBuffer(formatted)..writeln('\n');
    for (final issue in critical) {
      buffer.writeln('• ${issue.title}');
      if (issue.fixSteps.isNotEmpty) {
        buffer.writeln('  ${issue.fixSteps.first}');
      }
    }
    return buffer.toString().trim();
  }

  static String emulatorTestNumberHint() {
    if (!kDebugMode) return '';
    return 'Emulator/testing: add numbers in Firebase Console → Authentication → '
        'Sign-in method → Phone → Phone numbers for testing. '
        'Use the exact number and fixed OTP from the console (no SMS sent).';
  }
}

class _GoogleServicesClient {
  _GoogleServicesClient({
    required this.packageName,
    required this.appId,
    required this.oauthClientCount,
  });

  final String packageName;
  final String appId;
  final int oauthClientCount;
}

class _GoogleServicesParseResult {
  _GoogleServicesParseResult({required this.clients});

  final List<_GoogleServicesClient> clients;

  List<_GoogleServicesClient> clientsForPackage(String packageName) =>
      clients.where((c) => c.packageName == packageName).toList();
}

Future<_GoogleServicesParseResult?> _parseGoogleServicesJson() async {
  try {
    final raw = await rootBundle.loadString(FirebaseConfigAudit._googleServicesAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final clients = <_GoogleServicesClient>[];
    final clientList = json['client'] as List<dynamic>? ?? [];
    for (final entry in clientList) {
      final map = entry as Map<String, dynamic>;
      final info = map['client_info'] as Map<String, dynamic>?;
      final android = info?['android_client_info'] as Map<String, dynamic>?;
      final package = android?['package_name'] as String? ?? '';
      final appId = info?['mobilesdk_app_id'] as String? ?? '';
      final oauth = map['oauth_client'] as List<dynamic>? ?? [];
      if (package.isNotEmpty) {
        clients.add(
          _GoogleServicesClient(
            packageName: package,
            appId: appId,
            oauthClientCount: oauth.length,
          ),
        );
      }
    }
    return _GoogleServicesParseResult(clients: clients);
  } catch (_) {
    return null;
  }
}
