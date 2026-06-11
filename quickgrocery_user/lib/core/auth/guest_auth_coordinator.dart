import 'package:flutter/foundation.dart';

/// Actions to resume automatically after a guest completes phone login.
enum GuestPostLoginAction {
  none,
  continueCheckout,
}

/// Cross-cutting guest-mode signals shared by bootstrap, cart, and auth.
abstract final class GuestAuthCoordinator {
  static final guestModeTick = ValueNotifier<int>(0);

  static GuestPostLoginAction _pendingAction = GuestPostLoginAction.none;

  /// Set by [AuthSessionManager] so cart is not wiped during logout → guest.
  static bool preserveCartOnSignOut = false;

  static void notifyGuestModeEntered() {
    guestModeTick.value++;
  }

  static void setPendingAction(GuestPostLoginAction action) {
    _pendingAction = action;
  }

  static GuestPostLoginAction consumePendingAction() {
    final action = _pendingAction;
    _pendingAction = GuestPostLoginAction.none;
    return action;
  }
}
