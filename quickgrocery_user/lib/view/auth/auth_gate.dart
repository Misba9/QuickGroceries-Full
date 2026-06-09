import 'package:flutter/material.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_shell.dart';

/// Deprecated — routing now lives in [AppBootstrapShell].
@Deprecated('Use AppBootstrapShell instead')
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static void markOnboardingComplete(BuildContext context) {
    AppBootstrapShell.markOnboardingComplete(context);
  }

  @override
  Widget build(BuildContext context) => const AppBootstrapShell();
}
