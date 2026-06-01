import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/core/firebase/firebase_options.dart';
import 'package:quickgrocery/core/firebase/firebase_startup_validation.dart';

/// Initializes Firebase with bounded retries (transient startup / network).
///
/// Always uses [DefaultFirebaseOptions.currentPlatform] so the runtime appId
/// matches "customer new" (db7a0d4…) and never the removed duplicate app.
Future<void> initializeFirebaseWithRetry({
  int maxAttempts = 5,
  Duration initialDelay = const Duration(milliseconds: 400),
}) async {
  Object? lastError;
  StackTrace? lastStack;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          await Firebase.initializeApp();
        } else {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          if (kDebugMode) {
            debugPrint(
              '[Firebase] initialized with DefaultFirebaseOptions.currentPlatform '
              'appId=${DefaultFirebaseOptions.currentPlatform.appId}',
            );
          }
        }
      }
      await FirebaseStartupValidation.logAndValidate();
      await FirebaseConfigAudit.logConfiguration();
      return;
    } catch (e, st) {
      lastError = e;
      lastStack = st;
      if (kDebugMode) {
        debugPrint(
          '[Firebase] initializeApp attempt ${attempt + 1}/$maxAttempts failed: $e',
        );
      }
      if (attempt < maxAttempts - 1) {
        final ms = (initialDelay.inMilliseconds * math.pow(2, attempt)).round();
        await Future<void>.delayed(Duration(milliseconds: ms.clamp(200, 5000)));
      }
    }
  }
  Error.throwWithStackTrace(
    lastError ?? StateError('Firebase.initializeApp failed'),
    lastStack ?? StackTrace.empty,
  );
}
