import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/auth/phone_sign_in_navigation.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';

/// Imperative navigation for the phone-auth flow — always uses [rootNavigatorKey]
/// so OTP opens even when [LoginScreen]'s context is unmounted after reCAPTCHA.
abstract final class PhoneAuthCoordinator {
  static bool _otpRouteOpen = false;

  static bool get isOtpRouteOpen => _otpRouteVisible;

  static bool get _otpRouteVisible =>
      _otpRouteOpen || appRouteObserver.isCurrent(AppRoutes.otp);

  /// Push OTP screen once per verification session (soft transition).
  static void openOtpScreen() {
    if (_otpRouteVisible) {
      FirebasePhoneAuthLogger.info('navigate: OTP already open — skip');
      return;
    }

    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      FirebasePhoneAuthLogger.warn(
        'navigate: root navigator null — retry next frame',
      );
      SchedulerBinding.instance.addPostFrameCallback((_) => openOtpScreen());
      return;
    }

    FirebasePhoneAuthLogger.info('navigate: OTP screen opened');
    _otpRouteOpen = true;
    nav.push<void>(AppPageRoutes.otp()).whenComplete(() {
      _otpRouteOpen = false;
      FirebasePhoneAuthLogger.info('navigate: OTP screen closed');
    });
  }

  /// Prefer [PhoneSignInNavigation.clearAuthRoutesWhenReady] — single owner.
  @Deprecated('Use PhoneSignInNavigation.clearAuthRoutesWhenReady')
  static void clearAuthRoutes() {
    // ignore: discarded_futures
    PhoneSignInNavigation.clearAuthRoutesWhenReady();
  }

  static void reset() {
    _otpRouteOpen = false;
  }
}
