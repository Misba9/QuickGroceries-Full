import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/auth/phone_auth_flow_log.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';

/// Clears login/OTP routes pushed above [AppBootstrapShell] after phone sign-in.
abstract final class PhoneSignInNavigation {
  /// Pop auth routes once Firebase session exists. Safe to call multiple times.
  static Future<void> clearAuthRoutesWhenReady() async {
    PhoneAuthFlowLog.navigation('clearAuthRoutes scheduled');

    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
      if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
        await SchedulerBinding.instance.endOfFrame;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PhoneAuthFlowLog.navigation('clearAuthRoutes aborted — currentUser null');
      return;
    }

    final nav = rootNavigatorKey.currentState;
    if (nav == null || !nav.mounted) {
      PhoneAuthFlowLog.navigation('clearAuthRoutes aborted — navigator null');
      return;
    }
    if (!nav.canPop()) {
      PhoneAuthFlowLog.navigation('clearAuthRoutes — nothing to pop');
      return;
    }

    PhoneAuthFlowLog.navigation(
      'clearAuthRoutes popUntil first uid=${user.uid}',
    );
    nav.popUntil((route) => route.isFirst);
  }
}
