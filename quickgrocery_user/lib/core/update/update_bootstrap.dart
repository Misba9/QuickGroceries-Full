import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/core/startup/post_home_startup.dart';
import 'package:quickgrocery/core/update/update_mode.dart';
import 'package:quickgrocery/core/update/update_service.dart';
import 'package:quickgrocery/core/auth/auth_user_provider.dart';

/// Runs update checks after Home is visible, after auth changes, and on resume.
///
/// Exactly **one** cold-start check per process. Never races bootstrap +
/// cold_start into duplicate Remote Config fetches.
class AppUpdateBootstrap extends ConsumerStatefulWidget {
  const AppUpdateBootstrap({
    super.key,
    required this.child,
    this.mode = UpdateMode.remoteControlled,
  });

  final Widget child;
  final UpdateMode mode;

  @override
  ConsumerState<AppUpdateBootstrap> createState() => _AppUpdateBootstrapState();
}

class _AppUpdateBootstrapState extends ConsumerState<AppUpdateBootstrap>
    with WidgetsBindingObserver {
  late final AppUpdateService _service =
      AppUpdateService(mode: widget.mode);
  DateTime? _lastResumeCheck;
  bool _started = false;
  bool _checkInFlight = false;
  bool _initialCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PostHomeStartup.homeVisible.addListener(_onHomeVisible);
  }

  @override
  void dispose() {
    PostHomeStartup.homeVisible.removeListener(_onHomeVisible);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onHomeVisible() {
    if (!PostHomeStartup.homeVisible.value) return;
    _scheduleInitialCheckIfReady();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!PostHomeStartup.homeVisible.value) return;
    final now = DateTime.now();
    if (_lastResumeCheck != null &&
        now.difference(_lastResumeCheck!) < const Duration(minutes: 5)) {
      return;
    }
    _lastResumeCheck = now;
    unawaited(_runCheck(reason: 'resume'));
  }

  Future<void> _runCheck({required String reason}) async {
    if (!mounted) return;
    if (!PostHomeStartup.homeVisible.value) return;
    if (!ref.read(appBootstrapCompleteProvider)) return;
    if (_checkInFlight) return;
    // One cold-start / bootstrap check only.
    if (_started && (reason == 'cold_start' || reason == 'bootstrap')) {
      return;
    }

    final top = appRouteObserver.topRouteName;
    if (top == AppRoutes.otp ||
        top == AppRoutes.login ||
        top == AppRoutes.payment ||
        top == AppRoutes.checkout) {
      return;
    }

    _checkInFlight = true;
    try {
      await _service.flushPendingIfSafe(context);
      if (!mounted) return;
      await _service.checkAndPrompt(context);
      _started = true;
    } finally {
      _checkInFlight = false;
    }
  }

  void _scheduleInitialCheckIfReady() {
    if (_initialCheckScheduled) return;
    if (!PostHomeStartup.homeVisible.value) return;
    if (!ref.read(appBootstrapCompleteProvider)) return;
    _initialCheckScheduled = true;
    // Frame +28 — after FCM / analytics / RC warm, never during first paint.
    PostHomeStartup.onFrame(28, () {
      unawaited(_runCheck(reason: 'cold_start'));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Do not call schedule from build on every rebuild — only when
    // bootstrap flips to complete after Home is already visible.
    ref.listen<bool>(appBootstrapCompleteProvider, (prev, next) {
      if (next == true && prev != true) {
        _scheduleInitialCheckIfReady();
      }
    });

    ref.listen(authUserProvider, (prev, next) {
      if (!_started) return;
      next.whenData((user) {
        if (user != null) {
          unawaited(_runCheck(reason: 'login'));
        }
      });
    });

    return widget.child;
  }
}
