import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/auth/auth_session_log.dart';
import 'package:quickgrocery/core/auth/auth_session_provider_reset.dart';
import 'package:quickgrocery/core/auth/auth_sign_out_coordinator.dart';
import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/auth/guest_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/guest_session_provider.dart';
import 'package:quickgrocery/core/auth/phone_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/session_legacy_services.dart';
import 'package:quickgrocery/core/auth/user_session_store.dart';
import 'package:quickgrocery/view/cart/data/guest_cart_store.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';

/// Central sign-out — clears every user-scoped layer so account B never
/// inherits account A state. Does **not** replace the nav root; [AppBootstrapShell]
/// shows login when [FirebaseAuth.currentUser] becomes null.
abstract final class AuthSessionManager {
  /// Full logout from a widget tree that has legacy [Provider] services.
  static Future<void> signOutFromContext({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return signOut(
      ref: ref,
      legacy: SessionLegacyServices.fromContext(context),
    );
  }

  static Future<void> signOut({
    required WidgetRef ref,
    required SessionLegacyServices legacy,
  }) async {
    final previousUid = FirebaseAuth.instance.currentUser?.uid;
    AuthSessionLog.logoutStarted(uid: previousUid);

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final cartItems = ref.read(cartProvider).items;
      await GuestCartStore.saveItems(prefs, cartItems);
      GuestAuthCoordinator.preserveCartOnSignOut = true;
      await ref.read(guestSessionProvider.notifier).enable();
      GuestAuthCoordinator.notifyGuestModeEntered();

      legacy.resetInMemoryState();
      PhoneAuthCoordinator.reset();
      AuthSessionLog.inMemoryStateCleared();

      AuthSessionProviderReset.prepareForSignOut(ref);
      await UserSessionStore.clearUserData(prefs);
      AuthSessionLog.userCacheCleared();
      AuthSessionLog.sessionCleared();

      await FirebaseAuth.instance.signOut();

      _clearNavigationStackToLogin();

      // Defer stream invalidation so listeners (e.g. GlobalCartOverlay) do not
      // mutate the element tree during an in-flight build.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        AuthSessionProviderReset.invalidateUserProviders(ref);
        ref.invalidate(authUserProvider);
        AuthSessionLog.providersReset();
      });

      AuthSignOutCoordinator.notifySignedOut();
      AuthSessionLog.firebaseSignOutCompleted(previousUid: previousUid);
      AuthSessionLog.authListenerState(
        streamUid: null,
        syncUid: FirebaseAuth.instance.currentUser?.uid,
      );

      assert(
        FirebaseAuth.instance.currentUser == null,
        'FirebaseAuth.currentUser must be null after signOut',
      );

      AuthSessionLog.navigationToLogin();
      AuthSessionLog.logoutCompleted();
    } catch (e, st) {
      AuthSessionLog.exception('signOut', e, st);
      rethrow;
    }
  }

  /// Clears pushed routes; login is shown by [AppBootstrapShell] auth gate
  /// (equivalent to pushAndRemoveUntil LoginScreen without destroying the shell).
  static void _clearNavigationStackToLogin() {
    final nav = rootNavigatorKey.currentState;
    if (nav == null || !nav.mounted) return;
    nav.popUntil((route) => route.isFirst);
  }

  /// Drop cached profile/home data when a different UID signs in.
  static Future<void> ensureCacheMatchesUser(String uid) async {
    final cachedUid = await UserProfileCache.readCachedUid();
    if (cachedUid == null || cachedUid == uid) return;
    AuthSessionLog.staleCacheCleared(previousUid: cachedUid, newUid: uid);
    final prefs = await SharedPreferences.getInstance();
    await UserSessionStore.clearUserData(prefs);
  }

  static void prepareNewLogin() {
    PhoneAuthCoordinator.reset();
    AuthSessionLog.newLoginPrepared();
  }
}
