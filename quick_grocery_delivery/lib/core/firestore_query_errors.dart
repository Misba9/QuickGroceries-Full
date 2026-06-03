import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Shared helpers for Firestore composite-index failures.
class FirestoreQueryErrors {
  FirestoreQueryErrors._();

  static bool isMissingIndex(Object error) {
    if (error is FirebaseException) {
      return error.code == 'failed-precondition';
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('failed-precondition') ||
        msg.contains('requires an index');
  }

  static void log(String context, Object error, StackTrace stack) {
    debugPrint('$context: $error\n$stack');
  }
}
