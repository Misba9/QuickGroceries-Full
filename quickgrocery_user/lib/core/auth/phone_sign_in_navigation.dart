import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/auth/phone_auth_flow_log.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';

/// Clears login/OTP routes pushed above [AppBootstrapShell] after phone sign-in.
///
/// Exactly **one** pop-to-root per uid sign-in — duplicate callers are no-ops.
abstract final class PhoneSignInNavigation {
  static bool _inFlight = false;
  static String? _clearedForUid;

  /// Pop auth routes once Firebase session exists.
  static Future<void> clearAuthRoutesWhenReady() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PhoneAuthFlowLog.navigation('clearAuthRoutes aborted — currentUser null');
      return;
    }

    if (_inFlight) {
      PhoneAuthFlowLog.navigation('clearAuthRoutes skipped — already in flight');
      return;
    }
    if (_clearedForUid == user.uid) {
      final nav = rootNavigatorKey.currentState;
      if (nav == null || !nav.canPop()) {
        PhoneAuthFlowLog.navigation('clearAuthRoutes skipped — already cleared');
        return;
      }
    }

    _inFlight = true;
    PhoneAuthFlowLog.navigation('clearAuthRoutes scheduled');

    try {
      // Wait until the current frame settles — never pop mid-build.
      for (var i = 0; i < 2; i++) {
        await Future<void>.delayed(Duration.zero);
        if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
          await SchedulerBinding.instance.endOfFrame;
        }
      }

      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        PhoneAuthFlowLog.navigation('clearAuthRoutes aborted — uid changed');
        return;
      }

      final nav = rootNavigatorKey.currentState;
      if (nav == null || !nav.mounted) {
        PhoneAuthFlowLog.navigation('clearAuthRoutes aborted — navigator null');
        return;
      }
      if (!nav.canPop()) {
        PhoneAuthFlowLog.navigation('clearAuthRoutes — nothing to pop');
        _clearedForUid = user.uid;
        return;
      }

      PhoneAuthFlowLog.navigation(
        'clearAuthRoutes popUntil first uid=${user.uid}',
      );
      nav.popUntil((route) => route.isFirst);
      _clearedForUid = user.uid;
    } finally {
      _inFlight = false;
    }
  }

  /// Allow a future sign-in (logout / guest) to clear auth routes again.
  static void reset() {
    _inFlight = false;
    _clearedForUid = null;
  }
}
