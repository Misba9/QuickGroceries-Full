import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:quickgrocery/core/firebase/firebase_app_check_bootstrap.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_bootstrap.dart';
import 'package:quickgrocery/core/push/fcm_bootstrap.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/view/home/data/services/product_index_backfill.dart';

/// Non-essential cold-start work — runs after the first Flutter frame.
///
/// Keeps [main] limited to Firebase + prefs so iOS can paint splash/home
/// without waiting on App Check, APNs, FCM topics, or catalog backfills.
abstract final class DeferredStartup {
  static bool _scheduled = false;
  static bool _ran = false;

  /// Schedule once from the first widget frame after [runApp].
  static void scheduleAfterFirstFrame() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(run());
    });
  }

  static Future<void> run() async {
    if (_ran) return;
    _ran = true;

    AppStartupLog.milestone('Deferred startup begin');

    try {
      await configureFirebaseAppCheck();
      AppStartupLog.milestone('Deferred App Check ready');
    } catch (e) {
      if (kDebugMode) debugPrint('[DeferredStartup] App Check: $e');
    }

    try {
      await configureFirebasePhoneAuth();
      AppStartupLog.milestone('Deferred Phone Auth settings ready');
    } catch (e) {
      if (kDebugMode) debugPrint('[DeferredStartup] Phone Auth: $e');
    }

    // FCM permission + APNs wait + topics — never block first paint.
    unawaited(() async {
      try {
        await FcmBootstrap.configure();
        AppStartupLog.milestone('Deferred FCM ready');
      } catch (e) {
        if (kDebugMode) debugPrint('[DeferredStartup] FCM: $e');
      }
    }());

    // Ensure explore can orderBy(product_index) — soft-fail if rules deny writes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ProductIndexBackfill.ensureIndexes());
    });

    AppStartupLog.milestone('Deferred startup scheduled work complete');
  }
}
