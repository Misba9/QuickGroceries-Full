import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/core/update/update_mode.dart';
import 'package:quickgrocery/core/update/update_service.dart';
import 'package:quickgrocery/core/auth/auth_user_provider.dart';

/// Runs update checks after bootstrap, after auth changes, and on resume.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runCheck(reason: 'cold_start'));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
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
    if (!ref.read(appBootstrapCompleteProvider)) return;

    final top = appRouteObserver.topRouteName;
    if (top == AppRoutes.otp ||
        top == AppRoutes.login ||
        top == AppRoutes.payment ||
        top == AppRoutes.checkout) {
      if (kDebugMode) {
        debugPrint('[AppUpdate] bootstrap skip ($reason) — on $top');
      }
      return;
    }

    if (kDebugMode) debugPrint('[AppUpdate] check ($reason)');
    await _service.flushPendingIfSafe(context);
    if (!mounted) return;
    await _service.checkAndPrompt(context);
    _started = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appBootstrapCompleteProvider, (prev, next) {
      if (next == true) unawaited(_runCheck(reason: 'bootstrap'));
    });

    // After login / guest → signed-in.
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
