import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        await Firebase.initializeApp();
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
