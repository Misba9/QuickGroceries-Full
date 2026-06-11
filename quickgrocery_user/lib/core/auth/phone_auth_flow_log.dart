import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Structured OTP / phone-sign-in logs (visible in logcat via [developer.log]).
abstract final class PhoneAuthFlowLog {
  static const _name = 'PhoneAuthFlow';

  static void _log(String event, [String detail = '']) {
    final line = detail.isEmpty ? event : '$event | $detail';
    developer.log(line, name: _name);
    if (kDebugMode) {
      debugPrint('[$_name] $line');
    }
  }

  static void otpVerificationStarted({required String verificationIdPrefix}) {
    _log('otp_verification_started', 'verificationId=$verificationIdPrefix…');
  }

  static void otpVerificationSuccess({required String uid}) {
    _log('otp_verification_success', 'firebaseUid=$uid');
  }

  static void otpVerificationFailed({required Object error, StackTrace? stack}) {
    developer.log(
      'otp_verification_failed',
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stack ?? StackTrace.current,
    );
    if (kDebugMode) {
      debugPrint('[$_name] otp_verification_failed | $error');
      if (stack != null) debugPrintStack(stackTrace: stack);
    }
  }

  static void sessionSaveStarted({required String uid}) {
    _log('session_save_started', 'firebaseUid=$uid');
  }

  static void sessionSaved({required String uid}) {
    _log('session_saved', 'firebaseUid=$uid');
  }

  static void profileHydrateScheduled({required String uid}) {
    _log('profile_hydrate_scheduled', 'firebaseUid=$uid');
  }

  static void profileLoaded({required String uid}) {
    _log('profile_loaded', 'firebaseUid=$uid');
  }

  static void authStateChanged({String? uid, String? syncUid}) {
    _log(
      'auth_listener_triggered',
      'streamUid=${uid ?? 'null'} syncUid=${syncUid ?? 'null'}',
    );
  }

  static void syncAuthStarted({
    String? syncUid,
    String? streamUid,
    String? bootUid,
  }) {
    _log(
      'sync_auth_started',
      'syncUid=${syncUid ?? 'null'} streamUid=${streamUid ?? 'null'} '
      'bootUid=${bootUid ?? 'null'}',
    );
  }

  static void syncAuthIgnoredTransientNull() {
    _log('sync_auth_ignored', 'transient null (currentUser still set)');
  }

  static void syncAuthSignedOut() {
    _log('sync_auth_signed_out');
  }

  static void navigation(String detail) {
    _log('navigation', detail);
  }

  static void shellDestination(String destination) {
    _log('shell_destination', destination);
  }

  static void exception(String phase, Object error, [StackTrace? stack]) {
    developer.log(
      'exception phase=$phase',
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stack ?? StackTrace.current,
    );
    if (kDebugMode) {
      debugPrint('[$_name] exception phase=$phase | $error');
      debugPrintStack(stackTrace: stack ?? StackTrace.current);
    }
  }
}
