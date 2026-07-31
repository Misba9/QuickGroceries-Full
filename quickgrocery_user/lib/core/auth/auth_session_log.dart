import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Session lifecycle logs for logout / account switch (logcat via [developer.log]).
abstract final class AuthSessionLog {
  static const _name = 'AuthSession';

  static void _log(String event, [String detail = '']) {
    final line = detail.isEmpty ? event : '$event | $detail';
    developer.log(line, name: _name);
    if (kDebugMode) {
      debugPrint('[$_name] $line');
    }
  }

  static void logoutStarted({String? uid}) {
    _log('logout_started', 'previousUid=${uid ?? 'null'}');
  }

  static void inMemoryStateCleared() {
    _log('in_memory_state_cleared');
  }

  static void providersReset() {
    _log('providers_reset');
  }

  static void userCacheCleared() {
    _log('user_cache_cleared');
  }

  static void sessionCleared() {
    _log('session_cleared');
  }

  static void firebaseSignOutCompleted({String? previousUid}) {
    _log(
      'firebase_signout_completed',
      'previousUid=${previousUid ?? 'null'} syncUid=null',
    );
  }

  static void authListenerState({String? streamUid, String? syncUid}) {
    _log(
      'auth_listener_state',
      'streamUid=${streamUid ?? 'null'} syncUid=${syncUid ?? 'null'}',
    );
  }

  static void navigationToHome() {
    _log(
      'navigation_to_home',
      'popUntil first — AppBootstrapShell → guest LandingScreen',
    );
  }

  static void navigationToLogin() {
    navigationToHome();
  }

  static void logoutCompleted() {
    _log('logout_completed');
  }

  static void newLoginStarted({String? phone}) {
    _log('new_login_started', phone != null ? 'phone=$phone' : 'fresh session');
  }

  static void newLoginPrepared() {
    _log('new_login_prepared', 'phone auth state reset');
  }

  static void otpVerified({required String uid}) {
    _log('otp_verified', 'firebaseUid=$uid');
  }

  static void newSessionCreated({required String uid}) {
    _log('new_session_created', 'firebaseUid=$uid');
  }

  static void homeNavigation({required String uid}) {
    _log('home_navigation', 'uid=$uid via AppBootstrapShell');
  }

  static void staleCacheCleared({required String previousUid, required String newUid}) {
    _log('stale_cache_cleared', 'was=$previousUid now=$newUid');
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
