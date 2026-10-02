import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/analytics/app_heatmap_tracker.dart';
import 'package:quickgrocery/core/firebase/firebase_app_check_bootstrap.dart';
import 'package:quickgrocery/core/firebase/firebase_phone_auth_bootstrap.dart';
import 'package:quickgrocery/core/push/fcm_bootstrap.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/update/remote_config_service.dart';
import 'package:quickgrocery/core/user/device_profile_sync.dart';
import 'package:quickgrocery/view/home/data/services/product_index_backfill.dart';

/// Post–first-paint scheduler. Spreads heavy work across frames so Choreographer
/// stays near 16ms. Critical splash→Home path must finish before this runs.
///
/// Frame offsets (after Home's first painted frame):
///   +2  connectivity · +4 geolocator · +6 Firestore secondary
///   +8  pricing · +10 banners / image precache · +11 explore · +12 featured
///   +13 trending · +14 recommended · +16 flash · +18 recently ordered / catalog
///   +20 FCM · +22 topics · +24 analytics · +25 App Check
///   +26 Remote Config · +27 phone-auth settings · +28 App Update
///   +30 product indexing
/// Ticker stops at frame 32 (was 40) to cut forced scheduleFrame CPU.
abstract final class PostHomeStartup {
  PostHomeStartup._();

  static bool _scheduled = false;
  static bool _ticking = false;

  /// True once Home has completed its first frame.
  static final ValueNotifier<bool> homeVisible = ValueNotifier(false);

  /// Frames elapsed since [homeVisible] became true (0 = first Home frame).
  static final ValueNotifier<int> elapsedFrames = ValueNotifier(0);

  static final List<Future<void> Function()> _pending = [];
  static final Map<int, List<VoidCallback>> _frameHooks = {};

  /// True when at least [frame] frames have elapsed after Home first paint.
  static bool armedAt(int frame) =>
      homeVisible.value && elapsedFrames.value >= frame;

  /// Queue bootstrap catalog work — runs at frame +6, not immediately.
  static void enqueue(Future<void> Function() task) {
    if (armedAt(6)) {
      unawaited(task());
      return;
    }
    _pending.add(task);
  }

  /// Register a one-shot callback for a specific post-Home frame offset.
  static void onFrame(int frame, VoidCallback action) {
    if (armedAt(frame)) {
      action();
      return;
    }
    (_frameHooks[frame] ??= []).add(action);
  }

  /// Call once from `_ReadyHome` when Landing/Home mounts.
  static void scheduleAfterHomeVisible() {
    if (_scheduled) return;
    _scheduled = true;

    // Frame 0 = first Home paint.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      homeVisible.value = true;
      elapsedFrames.value = 0;
      _fireHooks(0);
      if (!_ticking) {
        _ticking = true;
        _advance();
      }
    });
  }

  static void _advance() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final next = elapsedFrames.value + 1;
      elapsedFrames.value = next;
      _fireHooks(next);
      _runBuiltIn(next);
      if (next < _lastRequiredFrame) {
        SchedulerBinding.instance.scheduleFrame();
        _advance();
      } else {
        _ticking = false;
      }
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  /// Stop forcing frames once Home arm gates + builtins are covered.
  /// Still reaches ≥30 for FCM/RC/App Check; skips idle 31–32 when unused.
  static int get _lastRequiredFrame {
    var last = 30;
    for (final f in _frameHooks.keys) {
      if (f > last) last = f;
    }
    // Home section arming (banners/rails) tops out ~18; keep ≤32 hard cap.
    if (last > 32) last = 32;
    return last;
  }

  static void _fireHooks(int frame) {
    final hooks = _frameHooks.remove(frame);
    if (hooks == null) return;
    for (final h in hooks) {
      try {
        h();
      } catch (e) {
        if (kDebugMode) debugPrint('[PostHomeStartup] hook@$frame: $e');
      }
    }
  }

  static void _runBuiltIn(int frame) {
    switch (frame) {
      case 6:
        _drainPending();
        break;
      case 20:
        unawaited(_initFcmPlugin());
        break;
      case 22:
        unawaited(_subscribeTopics());
        break;
      case 24:
        unawaited(_runAnalytics());
        break;
      case 25:
        unawaited(_runAppCheck());
        break;
      case 26:
        unawaited(_runRemoteConfig());
        break;
      case 27:
        unawaited(_runPhoneAuthSettings());
        break;
      case 30:
        unawaited(ProductIndexBackfill.ensureIndexes(batchSize: 60));
        break;
    }
  }

  static void _drainPending() {
    final queued = List<Future<void> Function()>.from(_pending);
    _pending.clear();
    // One task per subsequent frame — never burst.
    var i = 0;
    void next() {
      if (i >= queued.length) return;
      final task = queued[i++];
      unawaited(() async {
        try {
          await task();
        } catch (e) {
          if (kDebugMode) debugPrint('[PostHomeStartup] pending: $e');
        }
      }());
      if (i < queued.length) {
        SchedulerBinding.instance.addPostFrameCallback((_) => next());
        SchedulerBinding.instance.scheduleFrame();
      }
    }

    if (queued.isNotEmpty) next();
    AppStartupLog.milestone('Post-home pending drain start', 'n=${queued.length}');
  }

  static Future<void> _initFcmPlugin() async {
    try {
      if (!kIsWeb) await FcmPushInitializer.ensureInitialized();
      // Token only — topics on +22.
      await FcmBootstrap.configurePluginAndTokenOnly();
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] FCM init: $e');
    }
  }

  static Future<void> _subscribeTopics() async {
    try {
      await FcmBootstrap.subscribeDefaultTopics();
      AppStartupLog.milestone('Post-home FCM topics ready');
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] FCM topics: $e');
    }
  }

  static Future<void> _runAnalytics() async {
    try {
      await FirebaseAnalytics.instance.logAppOpen();
      AppHeatmapTracker.start();
      // Populate platform / app version for admin (existing users on reopen).
      unawaited(DeviceProfileSync.syncAfterStartup());
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] Analytics: $e');
    }
  }

  static Future<void> _runAppCheck() async {
    try {
      await configureFirebaseAppCheck();
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] App Check: $e');
    }
  }

  static Future<void> _runRemoteConfig() async {
    try {
      // Warm RC cache for App Update (+28) — no UI prompts here.
      await UpdateRemoteConfigService().fetchConfig();
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] Remote Config: $e');
    }
  }

  static Future<void> _runPhoneAuthSettings() async {
    try {
      // Settings only — no config audit / diagnostic dump.
      await configureFirebasePhoneAuth(logDiagnostics: false);
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHomeStartup] Phone Auth: $e');
    }
  }
}

@Deprecated('Use PostHomeStartup.scheduleAfterHomeVisible')
abstract final class DeferredStartup {
  static void scheduleAfterFirstFrame() {}
  static Future<void> run() => Future<void>.value();
}
