import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/firebase_options.dart';
import 'package:quickgrocery/core/firebase/google_services_parser.dart';

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

  /// Why [oauth_client] can be empty even when SHA is shown in Firebase Console.
  static String oauthClientEmptyExplanation({
    required String firebaseAppId,
    required String packageName,
  }) {
    return 'WHY oauth_client IS EMPTY\n'
        'Firebase app: $firebaseAppId\n'
        'Package: $packageName ("customer new")\n\n'
        'The Firebase API still returns oauth_client: [] for this app. '
        'That means Google Cloud has not created an Android OAuth 2.0 client '
        'linked to your SHA-1 yet — Phone Auth then fails with '
        '"missing a valid app identifier".\n\n'
        'Fix in Firebase Console (app "customer new"):\n'
        '1. Project settings → Android app com.quickgrocery.io\n'
        '2. Confirm SHA-1 exactly matches debug keystore:\n'
        '   $debugSha1\n'
        '3. Remove wrong SHA entries, re-add, wait 5–15 min\n'
        '4. Download google-services.json again (oauth_client must be non-empty)\n'
        '5. Google Cloud Console → APIs & Credentials → OAuth 2.0 Client IDs\n'
        '   → verify Android client for $packageName exists\n'
        '6. Authentication → Sign-in method → Phone → enabled\n'
        '7. App Check → register debug token if Auth is enforced';
  }

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
      final gs = await GoogleServicesConfig.loadFromAssets();
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
        final match =
            gs.clients.where((c) => c.packageName == installedId).toList();
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
                'Remove unused duplicate Android apps in Firebase Console if any',
                'Keep appId: $expectedAndroidAppId',
              ],
              severity: severity,
            ),
          );
        }

        final primary = gs.clientForAppId(expectedAndroidAppId) ??
            gs.clientForPackage(installedId);
        if (primary == null) {
          issues.add(
            FirebaseConfigIssue(
              id: 'gs-client-missing',
              title: 'google-services.json client not found',
              detail: 'No entry for $expectedAndroidAppId / $installedId.',
              fixSteps: [
                'Replace android/app/google-services.json from Firebase Console.',
              ],
            ),
          );
        } else {
        gsAppId = primary.mobileSdkAppId;
        oauthCount = primary.oauthClientCount;

        if (primary.mobileSdkAppId == expectedAndroidAppId) {
          passed.add('google-services.json appId matches firebase_options.dart');
        } else if (appId == expectedAndroidAppId) {
          issues.add(
            FirebaseConfigIssue(
              id: 'google-services-wrong-app-id',
              title: 'google-services.json points to wrong Firebase app',
              detail:
                  'Expected appId $expectedAndroidAppId ("customer new") but '
                  'google-services.json primary entry is ${primary.mobileSdkAppId}.',
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
              title: 'oauth_client empty (Google OAuth client not created)',
              detail: oauthClientEmptyExplanation(
                firebaseAppId: primary.mobileSdkAppId,
                packageName: primary.packageName,
              ),
              fixSteps: [
                'Re-add SHA-1 $debugSha1 on Firebase app db7a0d4…',
                'Re-download google-services.json when oauth_client is populated',
                'Open Firebase diagnostics screen in app (debug login)',
              ],
              severity: 'warning',
            ),
          );
        } else {
          passed.add(
            'google-services.json has ${primary.oauthClientCount} oauth_client(s)',
          );
        }
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

    if (appId != DefaultFirebaseOptions.ios.appId) {
      issues.add(
        FirebaseConfigIssue(
          id: 'ios-app-id-mismatch',
          title: 'iOS Firebase appId mismatch',
          detail:
              'Runtime appId "$appId" ≠ firebase_options ${DefaultFirebaseOptions.ios.appId}.',
          fixSteps: [
            'Run: flutterfire configure',
            'Ensure ios/Runner/GoogleService-Info.plist matches.',
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
}
