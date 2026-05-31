import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:quickgrocery/core/firebase/firebase_options.dart';

/// Initializes Firebase with bounded retries (transient startup / network).
///
/// Uses default native options from `google-services.json` / `GoogleService-Info.plist`.
/// For explicit Dart options across flavors, run `flutterfire configure` and pass
/// [FirebaseOptions] to [Firebase.initializeApp].
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
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          // Prefer GoogleService-Info.plist in the app bundle when present.
          try {
            await Firebase.initializeApp();
            if (kDebugMode) {
              debugPrint(
                '[Firebase] iOS initialized from GoogleService-Info.plist '
                'appId=${Firebase.app().options.appId} '
                'bundle=${Firebase.app().options.iosBundleId}',
              );
            }
          } catch (_) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.ios,
            );
            if (kDebugMode) {
              debugPrint(
                '[Firebase] iOS initialized from Dart options '
                'appId=${DefaultFirebaseOptions.ios.appId} '
                'bundle=${DefaultFirebaseOptions.ios.iosBundleId}',
              );
            }
          }
        } else {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.android,
          );
        }
      }
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
