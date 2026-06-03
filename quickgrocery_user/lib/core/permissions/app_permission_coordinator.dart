import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time OS permission prompts — never nag repeatedly.
abstract final class AppPermissionCoordinator {
  static const _notifAsked = 'notif_permission_asked';
  static const _notifDenied = 'notif_permission_denied';
  static const _locationGranted = 'location_permission_granted';

  static Future<bool> notificationAlreadyAsked() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(_notifAsked) ?? false;
  }

  static Future<bool> notificationDenied() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(_notifDenied) ?? false;
  }

  /// FCM permission — asked at most once per install.
  static Future<void> requestNotificationPermissionOnce() async {
    final pref = await SharedPreferences.getInstance();
    if (pref.getBool(_notifAsked) == true) return;

    await pref.setBool(_notifAsked, true);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final denied = settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined;
    if (denied) {
      await pref.setBool(_notifDenied, true);
    } else {
      await pref.remove(_notifDenied);
    }
  }

  /// Android 13+ notification runtime permission — once.
  static Future<void> requestAndroidNotificationOnce() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final pref = await SharedPreferences.getInstance();
    if (pref.getBool(_notifAsked) == true) return;

    final status = await Permission.notification.status;
    if (status.isGranted) {
      await pref.setBool(_notifAsked, true);
      return;
    }
    if (status.isPermanentlyDenied) {
      await pref.setBool(_notifAsked, true);
      await pref.setBool(_notifDenied, true);
      return;
    }

    await pref.setBool(_notifAsked, true);
    final result = await Permission.notification.request();
    if (!result.isGranted) {
      await pref.setBool(_notifDenied, true);
    }
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
