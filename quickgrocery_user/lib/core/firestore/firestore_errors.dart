import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore / gRPC codes that often clear after backoff or network toggle.
bool isFirestoreTransient(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'resource-exhausted':
      case 'aborted':
      case 'cancelled':
        return true;
      default:
        return false;
    }
  }
  final s = error.toString().toLowerCase();
  return s.contains('unavailable') ||
      s.contains('deadline') ||
      s.contains('network');
}

String firestoreUserFacingMessage(Object error) {
  if (error is FirebaseException) {
    if (isFirestoreTransient(error)) {
      return 'We can’t reach the server right now. Check your connection and try again.';
    }
    if (error.code == 'permission-denied') {
      return 'You don’t have access to this data. Please sign in again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
