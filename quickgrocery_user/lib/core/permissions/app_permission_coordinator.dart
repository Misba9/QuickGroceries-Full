import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time OS permission prompts — never during splash / category loading.
///
/// Call [requestAfterAppReady] only after Home is painted, faded in, and
/// interactive for a short settle period.
abstract final class AppPermissionCoordinator {
  static const _notifAsked = 'notif_permission_asked';
  static const _notifDenied = 'notif_permission_denied';
  static const _locationGranted = 'location_permission_granted';

  static bool _postLaunchStarted = false;
  static bool _postLaunchSettled = false;
  static bool _requestingPostLaunchLocation = false;

  /// Bumps after post-launch permission flow finishes (granted or denied).
  static final ValueNotifier<int> settledTick = ValueNotifier(0);

  /// True once the deferred prompt flow has finished (or was skipped).
  static bool get hasSettled => _postLaunchSettled;

  /// True while prompts are scheduled / showing — block other mid-load asks.
  static bool get isPostLaunchInProgress =>
      _postLaunchStarted && !_postLaunchSettled;

  static Future<bool> notificationAlreadyAsked() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(_notifAsked) ?? false;
  }

  static Future<bool> notificationDenied() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(_notifDenied) ?? false;
  }

  /// Run once after logo + category startup handoff and Home is interactive.
  ///
  /// [settleDelay] lets the user see working pages before any system dialog.
  static Future<void> requestAfterAppReady({
    Future<void> Function()? requestIosLocalNotifications,
    Duration settleDelay = Duration.zero,
  }) async {
    if (_postLaunchStarted) return;
    _postLaunchStarted = true;

    try {
      if (settleDelay > Duration.zero) {
        await Future<void>.delayed(settleDelay);
      }

      await _requestNotificationPermissions(
        requestIosLocalNotifications: requestIosLocalNotifications,
      );
      // Brief gap so the two OS dialogs don't stack on the same frame.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _requestingPostLaunchLocation = true;
      try {
        await requestLocationIfNeeded(silent: false);
      } finally {
        _requestingPostLaunchLocation = false;
      }
    } finally {
      _postLaunchSettled = true;
      settledTick.value++;
    }
  }

  static Future<void> _requestNotificationPermissions({
    Future<void> Function()? requestIosLocalNotifications,
  }) async {
    final pref = await SharedPreferences.getInstance();
    if (pref.getBool(_notifAsked) == true) return;

    await pref.setBool(_notifAsked, true);

    var denied = false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (!status.isGranted && !status.isPermanentlyDenied) {
        final result = await Permission.notification.request();
        if (!result.isGranted) denied = true;
      } else if (status.isPermanentlyDenied || status.isDenied) {
        denied = !status.isGranted;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await requestIosLocalNotifications?.call();
      } catch (_) {}
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final fcmDenied =
        settings.authorizationStatus == AuthorizationStatus.denied ||
            settings.authorizationStatus == AuthorizationStatus.notDetermined;
    if (fcmDenied) denied = true;

    if (denied) {
      await pref.setBool(_notifDenied, true);
    } else {
      await pref.remove(_notifDenied);
    }
  }

  /// @deprecated Use [requestAfterAppReady] after Home is ready.
  static Future<void> requestNotificationPermissionOnce() async {
    await _requestNotificationPermissions();
  }

  /// @deprecated Android notifications are included in [requestAfterAppReady].
  static Future<void> requestAndroidNotificationOnce() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _requestNotificationPermissions();
  }

  static Future<bool> isLocationGranted() async {
    final pref = await SharedPreferences.getInstance();
    if (pref.getBool(_locationGranted) == true) return true;

    final ph = await Permission.locationWhenInUse.status;
    if (ph.isGranted) {
      await pref.setBool(_locationGranted, true);
      return true;
    }
    return false;
  }

  static Future<bool> requestLocationIfNeeded({bool silent = false}) async {
    if (await isLocationGranted()) return true;

    final ph = await Permission.locationWhenInUse.status;
    if (ph.isGranted) {
      final pref = await SharedPreferences.getInstance();
      await pref.setBool(_locationGranted, true);
      return true;
    }

    if (silent && ph.isDenied) return false;

    // Block mid-load prompts; only the post-launch flow (or after settle) may ask.
    if (!hasSettled && !_requestingPostLaunchLocation) return false;

    final result = await Permission.locationWhenInUse.request();
    if (result.isGranted) {
      final pref = await SharedPreferences.getInstance();
      await pref.setBool(_locationGranted, true);
      return true;
    }
    return false;
  }

  static Future<void> markNotificationDeniedBannerShown() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('notif_denied_banner_dismissed', true);
  }

  static Future<bool> shouldShowNotificationDeniedBanner() async {
    final pref = await SharedPreferences.getInstance();
    if (pref.getBool(_notifDenied) != true) return false;
    return pref.getBool('notif_denied_banner_dismissed') != true;
  }
}
