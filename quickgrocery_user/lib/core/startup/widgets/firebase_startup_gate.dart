import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/auth/guest_session_provider.dart';
import 'package:quickgrocery/core/firebase/firebase_bootstrap.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/startup/widgets/brand_logo_splash.dart';
import 'package:quickgrocery/core/widgets/startup_failure_screen.dart';
import 'package:quickgrocery/realtime/realtime_bootstrap.dart';

typedef FirebaseBackgroundHandler = Future<void> Function(RemoteMessage message);

/// Shows the launch splash on the first frame, then initializes Firebase
/// after paint so TTFF is not blocked by the native SDK.
class FirebaseStartupGate extends ConsumerStatefulWidget {
  const FirebaseStartupGate({
    super.key,
    required this.child,
    required this.backgroundMessageHandler,
    this.onCrashlyticsHandlersInstalled,
  });

  final Widget child;
  final FirebaseBackgroundHandler backgroundMessageHandler;
  final VoidCallback? onCrashlyticsHandlersInstalled;

  @override
  ConsumerState<FirebaseStartupGate> createState() =>
      _FirebaseStartupGateState();
}

class _FirebaseStartupGateState extends ConsumerState<FirebaseStartupGate> {
  bool _ready = false;
  Object? _error;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // First frame paints splash immediately; Firebase starts after.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initFirebase());
    });
  }

  Future<void> _initFirebase() async {
    if (_started) return;
    _started = true;

    try {
      await initializeFirebaseWithRetry();
      AppStartupLog.milestone('Firebase initialized');

      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      widget.onCrashlyticsHandlersInstalled?.call();

      // Once only — do not repeat in [RealtimeBootstrap.initState].
      RealtimeBootstrap.configureFirestore();
      FirebaseMessaging.onBackgroundMessage(widget.backgroundMessageHandler);

      // Re-bind auth streams now that Firebase.apps is non-empty.
      ref.invalidate(authUserProvider);
      ref.invalidate(guestSessionProvider);

      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (e, st) {
      try {
        await FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
      } catch (_) {}
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
      if (!mounted) return;
      setState(() {
        _error = e;
        _ready = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _started = false;
      _error = null;
      _ready = false;
    });
    await _initFirebase();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return StartupFailureScreen(
        error: _error!,
        onRetry: _retry,
      );
    }

    if (!_ready) {
      // STEP 1 bridge — same yellow + logo as native (0–400ms total hold).
      // Firebase init logic unchanged; categories start after logo hold.
      return const BrandLogoSplash();
    }

    return widget.child;
  }
}
