import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Maps deletion failures to user-facing copy (never raw Firebase stacks).
class AccountDeletionException implements Exception {
  AccountDeletionException(this.message, {this.needsReauth = false});

  final String message;
  final bool needsReauth;

  @override
  String toString() => message;
}

class AccountDeletionService {
  AccountDeletionService({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions = functions,
      _auth = auth ?? FirebaseAuth.instance,
      _regions = functions == null
          ? const ['us-central1', 'asia-south1']
          : const [];

  static const functionName = 'deleteMyAccountCallable';

  final FirebaseFunctions? _functions;
  final FirebaseAuth _auth;
  final List<String> _regions;

  /// Permanently deletes the signed-in user. UID is never taken from the UI.
  Future<void> deleteCurrentAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AccountDeletionException(
        'You need to be signed in to delete your account.',
      );
    }

    try {
      await user.getIdToken(true);
    } catch (e) {
      debugPrint('ACCOUNT_DELETE token refresh failed: $e');
    }

    try {
      await _callDelete();
    } on FirebaseFunctionsException catch (e) {
      if (_isAuthError(e)) {
        throw AccountDeletionException(
          'Please verify it is you, then try again.',
          needsReauth: true,
        );
      }
      throw AccountDeletionException(_friendlyFunctionsMessage(e));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AccountDeletionException(
          'Please verify it is you, then try again.',
          needsReauth: true,
        );
      }
      throw AccountDeletionException(_friendlyAuthMessage(e));
    }
  }

  Future<void> _callDelete() async {
    final injected = _functions;
    if (injected != null) {
      await injected
          .httpsCallable(
            functionName,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
          )
          .call(<String, dynamic>{});
      return;
    }

    FirebaseFunctionsException? last;
    for (final region in _regions) {
      try {
        await FirebaseFunctions.instanceFor(region: region)
            .httpsCallable(
              functionName,
              options: HttpsCallableOptions(
                timeout: const Duration(seconds: 120),
              ),
            )
            .call(<String, dynamic>{});
        return;
      } on FirebaseFunctionsException catch (e) {
        last = e;
        if (e.code == 'not-found' || e.code == 'unavailable') continue;
        rethrow;
      }
    }
    if (last != null) throw last;
    throw AccountDeletionException('We could not reach the account service.');
  }

  static bool _isAuthError(FirebaseFunctionsException e) {
    if (e.code == 'unauthenticated') return true;
    final message = (e.message ?? '').toLowerCase();
    return message.contains('unauthenticated') ||
        message.contains('sign in to delete');
  }

  static String _friendlyFunctionsMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        return 'The network timed out. Check your connection and try again.';
      case 'not-found':
        return 'Account deletion is temporarily unavailable. Please try again later.';
      default:
        final msg = e.message?.trim();
        if (msg != null &&
            msg.isNotEmpty &&
            !msg.toLowerCase().contains('exception') &&
            !msg.contains('firebase')) {
          return msg;
        }
        return 'We couldn\'t delete your account. Please try again.';
    }
  }

  static String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'The network timed out. Check your connection and try again.';
      default:
        return 'We couldn\'t delete your account. Please try again.';
    }
  }
}
