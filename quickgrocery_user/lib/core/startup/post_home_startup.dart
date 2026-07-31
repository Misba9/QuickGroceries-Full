import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:quickgrocery/core/firebase/firebase_app_check_bootstrap.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_bootstrap.dart';
import 'package:quickgrocery/core/push/fcm_bootstrap.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/view/home/data/services/product_index_backfill.dart';

/// Gates non-critical startup until [LandingScreen] / Home has painted.
///
/// Critical path (Firebase, auth, home snapshot, splash→Home) must finish
/// first. Call [scheduleAfterHomeVisible] from `_ReadyHome` after mount.
abstract final class PostHomeStartup {
  PostHomeStartup._();

  static bool _scheduled = false;
  static bool _ran = false;

  /// True after Home has completed at least one frame.
  static final ValueNotifier<bool> homeVisible = ValueNotifier(false);

  /// Pending work registered by bootstrap (heavy catalog, background refresh).
  static final List<Future<void> Function()> _pending = [];

  /// Queue work that must not run until Home is visible.
  static void enqueue(Future<void> Function() task) {
    if (_ran || homeVisible.value) {
      unawaited(task());
      return;
    }
    _pending.add(task);
  }

  /// Call once when Home / Landing is on screen.
  static void scheduleAfterHomeVisible() {
    if (_scheduled) return;
    _scheduled = true;

    // Two frames: first builds Home, second confirms it painted.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        homeVisible.value = true;
        unawaited(_run());
      });
    });
  }

  static Future<void> _run() async {
    if (_ran) return;
    _ran = true;

    AppStartupLog.milestone('Post-home startup begin');

    // Drain bootstrap-enqueued background work first (catalog / refresh).
    final queued = List<Future<void> Function()>.from(_pending);
    _pending.clear();
    for (final task in queued) {
      unawaited(() async {
        try {
          await task();
        } catch (e) {
          if (kDebugMode) debugPrint('[PostHomeStartup] queued task: $e');
        }
      }());
    }

    try {
      await configureFirebaseAppCheck();
      AppStartupLog.milestone('Post-home App Check ready');
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] App Check: $e');
    }

    try {
      await configureFirebasePhoneAuth();
      AppStartupLog.milestone('Post-home Phone Auth settings ready');
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] Phone Auth: $e');
    }

    unawaited(() async {
      try {
        await FcmBootstrap.configure();
        AppStartupLog.milestone('Post-home FCM ready');
      } catch (e) {
        if (kDebugMode) debugPrint('[PostHomeStartup] FCM: $e');
      }
    }());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ProductIndexBackfill.ensureIndexes());
    });

    AppStartupLog.milestone('Post-home startup scheduled');
  }
}

/// Back-compat alias — early first-frame deferral is replaced by post-home.
@Deprecated('Use PostHomeStartup.scheduleAfterHomeVisible')
abstract final class DeferredStartup {
  static void scheduleAfterFirstFrame() {
    // Intentionally no-op: non-critical work waits for Home (PostHomeStartup).
    if (kDebugMode) {
      debugPrint(
        '[DeferredStartup] skipped — waiting for PostHomeStartup after Home',
      );
    }
  }

  static Future<void> run() => Future<void>.value();
}
