import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/view/auth/screens/otp_screen.dart';

/// Imperative navigation for the phone-auth flow — always uses [rootNavigatorKey]
/// so OTP opens even when [LoginScreen]'s context is unmounted after reCAPTCHA.
abstract final class PhoneAuthCoordinator {
  static bool _otpRouteOpen = false;

  static bool get isOtpRouteOpen =>
      _otpRouteOpen || appRouteObserver.isCurrent(AppRoutes.otp);

  /// Push OTP screen once per verification session.
  static void openOtpScreen() {
    if (isOtpRouteOpen) {
      FirebasePhoneAuthLogger.info('navigate: OTP already open — skip');
      return;
    }

    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      FirebasePhoneAuthLogger.warn('navigate: root navigator null — retry next frame');
      SchedulerBinding.instance.addPostFrameCallback((_) => openOtpScreen());
      return;
    }

    FirebasePhoneAuthLogger.info('navigate: OTP screen opened');
    _otpRouteOpen = true;
    nav
        .push<void>(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: AppRoutes.otp),
            builder: (_) => const OtpAuthScreen(),
          ),
        )
        .whenComplete(() {
      _otpRouteOpen = false;
      FirebasePhoneAuthLogger.info('navigate: OTP screen closed');
    });
  }

  /// Remove login/OTP routes above [AppBootstrapShell] after sign-in succeeds.
  static void clearAuthRoutes() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final nav = rootNavigatorKey.currentState;
      if (nav == null || !nav.mounted) return;
      if (!nav.canPop()) {
        FirebasePhoneAuthLogger.info('navigate: clearAuthRoutes — nothing to pop');
        return;
      }
      FirebasePhoneAuthLogger.info('navigate: clearAuthRoutes popUntil first');
      _otpRouteOpen = false;
      nav.popUntil((route) => route.isFirst);
    });
  }

  static void reset() {
    _otpRouteOpen = false;
  }
}
