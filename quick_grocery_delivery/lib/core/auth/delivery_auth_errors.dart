import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Maps Firebase / partner auth failures to user-facing messages.
class DeliveryAuthErrors {
  DeliveryAuthErrors._();

  static String fromException(Object error) {
    if (error is DeliveryAuthException) return error.message;
    if (error is FirebaseAuthException) {
      return fromFirebaseAuthException(error);
    }
    if (error is FirebaseFunctionsException) {
      return fromFunctionsException(error);
    }
    final text = error.toString();
    if (text.contains('NOT_FOUND') || text.contains('not-found')) {
      return 'Delivery account not found. Ask admin to sync Firebase Auth.';
    }
    return text.replaceFirst('Exception: ', '').trim();
  }

  static String fromFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No delivery account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'Your account has been suspended.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  static String fromFunctionsException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
        return 'Delivery account not found. Check your email or contact support.';
      case 'permission-denied':
        return e.message ?? 'Your account has been suspended.';
      case 'resource-exhausted':
        return e.message ?? 'Too many attempts. Please try again later.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Network error. Check your connection and try again.';
      case 'invalid-argument':
        return e.message ?? 'Invalid login details.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  static void logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[DeliveryAuth] $message');
    }
  }
}

class DeliveryAuthException implements Exception {
  DeliveryAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
