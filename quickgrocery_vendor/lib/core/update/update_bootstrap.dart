import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:quickgrocery_vendor/core/update/update_mode.dart';
import 'package:quickgrocery_vendor/core/update/update_service.dart';

/// Runs update checks after first frame and on app resume.
class AppUpdateBootstrap extends StatefulWidget {
  const AppUpdateBootstrap({
    super.key,
    required this.child,
    this.mode = UpdateMode.remoteControlled,
  });

  final Widget child;
  final UpdateMode mode;

  @override
  State<AppUpdateBootstrap> createState() => _AppUpdateBootstrapState();
}

class _AppUpdateBootstrapState extends State<AppUpdateBootstrap>
    with WidgetsBindingObserver {
  late final AppUpdateService _service =
      AppUpdateService(mode: widget.mode);
  DateTime? _lastResumeCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_run('cold_start'));
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
    unawaited(_run('resume'));
  }

  Future<void> _run(String reason) async {
    if (!mounted) return;
    if (kDebugMode) debugPrint('[AppUpdate] check ($reason)');
    await _service.checkAndPrompt(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
