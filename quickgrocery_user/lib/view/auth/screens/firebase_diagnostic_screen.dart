import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:quickgrocery/core/firebase/app_check_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/core/firebase/firebase_options.dart';
import 'package:quickgrocery/core/firebase/google_services_parser.dart';

/// Debug screen: Firebase + Phone Auth configuration for com.quickgrocery.io.
class FirebaseDiagnosticScreen extends StatefulWidget {
  const FirebaseDiagnosticScreen({super.key});

  @override
  State<FirebaseDiagnosticScreen> createState() =>
      _FirebaseDiagnosticScreenState();
}

class _FirebaseDiagnosticScreenState extends State<FirebaseDiagnosticScreen> {
  String? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final buffer = StringBuffer();

    final packageInfo = await PackageInfo.fromPlatform();
    buffer.writeln('=== Installed app ===');
    buffer.writeln('Package name: ${packageInfo.packageName}');
    buffer.writeln('Expected: ${FirebaseConfigAudit.expectedAndroidPackage}');
    buffer.writeln(
      'Match: ${packageInfo.packageName == FirebaseConfigAudit.expectedAndroidPackage}',
    );
    buffer.writeln();

    if (Firebase.apps.isNotEmpty) {
      final app = Firebase.app();
      final o = app.options;
      buffer.writeln('=== Runtime Firebase ===');
      buffer.writeln('Firebase App Name: ${app.name}');
      buffer.writeln('Firebase App ID: ${o.appId}');
      buffer.writeln('Project ID: ${o.projectId}');
      buffer.writeln('Messaging Sender ID: ${o.messagingSenderId}');
      buffer.writeln('API key (prefix): ${o.apiKey.substring(0, 8)}…');
      buffer.writeln(
        'Matches DefaultFirebaseOptions: ${o.appId == DefaultFirebaseOptions.android.appId}',
      );
      buffer.writeln();
    } else {
      buffer.writeln('Firebase not initialized.\n');
    }

    buffer.writeln('=== DefaultFirebaseOptions (Dart) ===');
    buffer.writeln('Android appId: ${DefaultFirebaseOptions.android.appId}');
    buffer.writeln('Expected: ${FirebaseConfigAudit.expectedAndroidAppId}');
    buffer.writeln();

    final gs = await GoogleServicesConfig.loadFromAssets();
    buffer.writeln('=== google-services.json (bundled) ===');
    if (gs == null) {
      buffer.writeln('Could not load android/app/google-services.json');
    } else {
      buffer.writeln('project_id: ${gs.projectId}');
      buffer.writeln('project_number: ${gs.projectNumber}');
      final client = gs.clientForPackage(
        FirebaseConfigAudit.expectedAndroidPackage,
      );
      if (client == null) {
        buffer.writeln(
          'No client for package ${FirebaseConfigAudit.expectedAndroidPackage}',
        );
      } else {
        buffer.writeln('mobilesdk_app_id: ${client.mobileSdkAppId}');
        buffer.writeln('package_name: ${client.packageName}');
        buffer.writeln('api_key (prefix): ${client.apiKey.substring(0, 8)}…');
        buffer.writeln('oauth_client count: ${client.oauthClientCount}');
        buffer.writeln(
          'has Android OAuth (type 3): ${client.hasAndroidOAuthClient}',
        );
        if (client.oauthClientCount == 0) {
          buffer.writeln();
          buffer.writeln(FirebaseConfigAudit.oauthClientEmptyExplanation(
            firebaseAppId: client.mobileSdkAppId,
            packageName: client.packageName,
          ));
        } else {
          for (final oauth in client.oauthClients) {
            buffer.writeln(
              '  - type ${oauth.clientType} '
              '${oauth.androidPackage ?? ""} '
              'hash=${oauth.certificateHash ?? "n/a"}',
            );
          }
        }
      }
      if (gs.clients.length > 1) {
        buffer.writeln(
          '\nWARN: ${gs.clients.length} clients in file — should be 1 for user app.',
        );
      }
    }
    buffer.writeln();

    buffer.writeln('=== App Check ===');
    buffer.writeln(
      'Android: ${usePlayIntegrityAppCheck ? 'playIntegrity' : 'debug'} | '
      'Apple: ${useAppAttestAppCheck ? 'appAttestWithDeviceCheckFallback' : 'debug'} '
      '(kDebugMode=$kDebugMode kProfileMode=$kProfileMode kReleaseMode=$kReleaseMode)',
    );
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      buffer.writeln(
        'Token: ${token == null || token.isEmpty ? '(empty)' : '${token.substring(0, 12)}… (${token.length} chars)'}',
      );
    } catch (e) {
      buffer.writeln('Token error: $e');
    }
    buffer.writeln();

    buffer.writeln('=== SHA registration ===');
    buffer.writeln(FirebaseConfigAudit.shaFingerprintCommands());
    buffer.writeln('Expected debug SHA-1: ${FirebaseConfigAudit.debugSha1}');
    buffer.writeln('Expected debug SHA-256: ${FirebaseConfigAudit.debugSha256}');
    buffer.writeln();

    final audit = await FirebaseConfigAudit.runAudit();
    buffer.writeln(audit.toDebugString());
    buffer.writeln();
    buffer.writeln('Phone Auth ready: ${audit.isReadyForPhoneAuth}');

    if (!mounted) return;
    setState(() {
      _report = buffer.toString();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _report == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _report!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report copied')),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _report ?? '',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
    );
  }
}
