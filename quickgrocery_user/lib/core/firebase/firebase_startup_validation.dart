import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:quickgrocery/core/firebase/firebase_options.dart';
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
      debugPrint('[FirebaseStartup] Firebase not initialized yet');
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final app = Firebase.app();
    final options = app.options;
    final gs = await GoogleServicesConfig.loadFromAssets();
    final gsClient = gs?.clientForPackage(expectedPackageName);

    debugPrint(
      '[FirebaseStartup] '
      'firebaseAppName=${app.name} '
      'packageName=${packageInfo.packageName} '
      'appId=${options.appId} '
      'projectId=${options.projectId} '
      'messagingSenderId=${options.messagingSenderId}',
    );

    if (gs != null) {
      debugPrint(
        '[FirebaseStartup] google-services.json '
        'projectNumber=${gs.projectNumber} '
        'gsAppId=${gsClient?.mobileSdkAppId ?? "(none)"} '
        'oauthClientCount=${gsClient?.oauthClientCount ?? 0}',
      );
    }

    if (packageInfo.packageName != expectedPackageName) {
      debugPrint(
        '[FirebaseStartup] WARN package mismatch: '
        'expected $expectedPackageName got ${packageInfo.packageName}',
      );
    }

    if (options.appId != expectedAndroidAppId &&
        !options.appId.contains(':ios:')) {
      debugPrint(
        '[FirebaseStartup] ERROR appId mismatch: '
        'expected $expectedAndroidAppId got ${options.appId}',
      );
    }

    if (options.projectId != expectedProjectId) {
      debugPrint(
        '[FirebaseStartup] ERROR projectId mismatch: '
        'expected $expectedProjectId got ${options.projectId}',
      );
    }

    if (options.messagingSenderId != expectedMessagingSenderId) {
      debugPrint(
        '[FirebaseStartup] WARN messagingSenderId mismatch: '
        'expected $expectedMessagingSenderId got ${options.messagingSenderId}',
      );
    }

    final dartOptions = DefaultFirebaseOptions.currentPlatform;
    if (options.appId == dartOptions.appId) {
      debugPrint('[FirebaseStartup] OK runtime matches DefaultFirebaseOptions');
    } else {
      debugPrint(
        '[FirebaseStartup] ERROR runtime appId != DefaultFirebaseOptions: '
        '${options.appId} vs ${dartOptions.appId}',
      );
    }
  }
}
