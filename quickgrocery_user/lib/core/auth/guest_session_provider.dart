import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';

const _guestSessionKey = 'guest_session_enabled';

/// Persisted guest browsing flag — survives cold start and logout.
class GuestSessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (FirebaseAuth.instance.currentUser != null) return false;
    final prefs = ref.read(sharedPreferencesProvider);
    // Default true: never block cold start with a login screen.
    return prefs.getBool(_guestSessionKey) ?? true;
  }

  Future<void> enable() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_guestSessionKey, true);
  }

  Future<void> disable() async {
    if (!state) return;
    state = false;
    await ref.read(sharedPreferencesProvider).setBool(_guestSessionKey, false);
  }
}

final guestSessionProvider =
    NotifierProvider<GuestSessionNotifier, bool>(GuestSessionNotifier.new);

/// True when the user is browsing without a Firebase account.
final isGuestModeProvider = Provider<bool>((ref) {
  final authUser = resolveAuthUser(ref.watch(authUserProvider));
  return authUser == null;
});
