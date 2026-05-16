import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/core/firestore/firestore_errors.dart';

/// Runs [fn] with exponential backoff on transient Firestore / network errors.
///
/// Optionally toggles Firestore network after a failed attempt to nudge the
/// client connection (safe no-op when already connected).
Future<T> withFirestoreRetry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 4,
  Duration initialDelay = const Duration(milliseconds: 350),
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } on FirebaseException catch (e) {
      if (!isFirestoreTransient(e) || attempt >= maxAttempts - 1) rethrow;
      await _maybeResetNetwork(attempt);
      final ms = (initialDelay.inMilliseconds * math.pow(2, attempt)).round();
      await Future<void>.delayed(Duration(milliseconds: ms.clamp(200, 4000)));
    } catch (e) {
      if (!isFirestoreTransient(e) || attempt >= maxAttempts - 1) rethrow;
      await _maybeResetNetwork(attempt);
      final ms = (initialDelay.inMilliseconds * math.pow(2, attempt)).round();
      await Future<void>.delayed(Duration(milliseconds: ms.clamp(200, 4000)));
    }
  }
  throw StateError('withFirestoreRetry: exhausted without throw');
}

Future<void> _maybeResetNetwork(int attemptAfterFailure) async {
  if (attemptAfterFailure == 0) return;
  try {
    await FirebaseFirestore.instance.disableNetwork();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await FirebaseFirestore.instance.enableNetwork();
  } catch (_) {
    /* ignore — recovery hint only */
  }
}
