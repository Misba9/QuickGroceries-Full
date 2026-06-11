import 'package:flutter/foundation.dart';

/// Imperative hook so [AppBootstrapShell] runs bootstrap immediately after OTP
/// sign-in — do not rely only on [authStateChanges] timing vs route pops.
abstract final class AuthSignInCoordinator {
  static final ValueNotifier<int> signedInTick = ValueNotifier(0);

  static void notifyPhoneSignInComplete() {
    signedInTick.value++;
  }
}
