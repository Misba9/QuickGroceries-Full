import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/app_check_providers.dart';
import 'package:quickgrocery/core/firebase/firebase_options.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/firebase/google_services_parser.dart';

/// Logs and validates Firebase identity at startup.
class FirebaseStartupValidation {
  FirebaseStartupValidation._();

  static const expectedPackageName = 'com.quickgrocery.io';
  static const expectedAndroidAppId =
      '1:970937777233:android:db7a0d4e8b73454f6e0c70';
  static const expectedProjectId = 'quikgroceries';
  static const expectedMessagingSenderId = '970937777233';

  static Future<void> logAndValidate() async {
    if (Firebase.apps.isEmpty) {
      FirebasePhoneAuthLogger.warn('Firebase not initialized yet');
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final app = Firebase.app();
    final options = app.options;
    final gs = await GoogleServicesConfig.loadFromAssets();
    final gsClient = gs?.clientForPackage(expectedPackageName);

    FirebasePhoneAuthLogger.logRuntimeContext(
      packageName: packageInfo.packageName,
      projectId: options.projectId,
      appId: options.appId,
      appCheckProvider: appCheckAndroidProviderLabel,
    );

    if (gs != null) {
      final oauthCount = gsClient?.oauthClientCount ?? 0;
      FirebasePhoneAuthLogger.info(
        'google-services.json projectNumber=${gs.projectNumber} '
        'gsAppId=${gsClient?.mobileSdkAppId ?? "(none)"} '
        'oauthClientCount=$oauthCount',
      );
      if (!kIsWeb && oauthCount == 0) {
        FirebasePhoneAuthLogger.warn(
          'Bundled google-services.json oauthClientCount=0 for '
          '$expectedPackageName (informational — does not block OTP)',
        );
      }
    }

    if (packageInfo.packageName != expectedPackageName) {
      FirebasePhoneAuthLogger.error(
        'Package mismatch: expected $expectedPackageName got '
        '${packageInfo.packageName}',
      );
    }

    if (options.appId != expectedAndroidAppId &&
        !options.appId.contains(':ios:')) {
      FirebasePhoneAuthLogger.error(
        'appId mismatch: expected $expectedAndroidAppId got ${options.appId}',
      );
    }

    if (options.projectId != expectedProjectId) {
      FirebasePhoneAuthLogger.error(
        'projectId mismatch: expected $expectedProjectId got ${options.projectId}',
      );
    }

    if (options.messagingSenderId != expectedMessagingSenderId) {
      FirebasePhoneAuthLogger.warn(
        'messagingSenderId mismatch: expected $expectedMessagingSenderId '
        'got ${options.messagingSenderId}',
      );
    }

    final dartOptions = DefaultFirebaseOptions.currentPlatform;
    if (options.appId == dartOptions.appId) {
      FirebasePhoneAuthLogger.info('OK runtime matches DefaultFirebaseOptions');
    } else {
      FirebasePhoneAuthLogger.error(
        'runtime appId != DefaultFirebaseOptions: '
        '${options.appId} vs ${dartOptions.appId}',
      );
    }
  }
}
