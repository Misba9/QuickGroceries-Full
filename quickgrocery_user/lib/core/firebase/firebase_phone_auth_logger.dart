import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickgrocery/core/firebase/app_check_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Phone Auth logs visible in logcat via [developer.log] (debug + release).
class FirebasePhoneAuthLogger {
  FirebasePhoneAuthLogger._();

  static const _name = 'PhoneAuth';

  static void info(String message) {
    developer.log(message, name: _name);
    if (kDebugMode) {
      debugPrint('[$_name] $message');
    }
  }

  static void warn(String message) {
    developer.log(message, name: _name, level: 900);
    if (kDebugMode) {
      debugPrint('[$_name][WARN] $message');
    }
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      debugPrint('[$_name][ERROR] $message');
      if (error != null) debugPrint('[$_name][ERROR] $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void logAuthException(
    String phase,
    FirebaseAuthException e, {
    StackTrace? stackTrace,
  }) {
    error(
      '$phase FirebaseAuthException code=${e.code} message=${e.message}',
      error: e,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }

  static void logRuntimeContext({
    required String packageName,
    required String projectId,
    required String appId,
    required String appCheckProvider,
    String? firebaseAppName,
    String? phoneNumber,
    String? verificationIdPrefix,
    String? phase,
  }) {
    info(
      '${phase != null ? '$phase ' : ''}'
      'firebaseAppName=${firebaseAppName ?? '(unknown)'} '
      'package=$packageName projectId=$projectId appId=$appId '
      'appCheckProvider=$appCheckProvider'
      '${phoneNumber != null ? ' phone=$phoneNumber' : ''}'
      '${verificationIdPrefix != null ? ' verificationId=${verificationIdPrefix}…' : ''}',
    );
  }

  /// Full Firebase runtime snapshot immediately before/after SDK phone auth calls.
  static Future<void> logVerifyPhoneSnapshot({
    required String phase,
    String? phoneNumber,
  }) async {
    if (Firebase.apps.isEmpty) {
      warn('$phase Firebase.apps is empty — not initialized');
      return;
    }
    final app = Firebase.app();
    final options = app.options;
    final packageInfo = await PackageInfo.fromPlatform();
    logRuntimeContext(
      phase: phase,
      firebaseAppName: app.name,
      packageName: packageInfo.packageName,
      projectId: options.projectId,
      appId: options.appId,
      appCheckProvider: appCheckAndroidProviderLabel,
      phoneNumber: phoneNumber,
    );
  }
}
