import 'package:flutter/foundation.dart';

/// Notifies [AppBootstrapShell] to rebuild on the login screen after logout.
abstract final class AuthSignOutCoordinator {
  static final ValueNotifier<int> signedOutTick = ValueNotifier(0);

  static void notifySignedOut() {
    signedOutTick.value++;
  }
}
