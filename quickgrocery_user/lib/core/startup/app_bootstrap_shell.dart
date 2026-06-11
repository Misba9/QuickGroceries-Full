import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/auth/auth_sign_in_coordinator.dart';
import 'package:quickgrocery/core/auth/auth_sign_out_coordinator.dart';
import 'package:quickgrocery/core/auth/auth_session_log.dart';
import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/auth/guest_address_migrator.dart';
import 'package:quickgrocery/core/auth/guest_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/guest_session_provider.dart';
import 'package:quickgrocery/core/auth/phone_auth_flow_log.dart';
import 'package:quickgrocery/core/auth/phone_sign_in_navigation.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/navigation/home_shell_observer.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/startup/home_image_precache.dart';
import 'package:quickgrocery/core/startup/widgets/app_animated_splash.dart';
import 'package:quickgrocery/core/startup/widgets/bootstrap_error_screen.dart';
import 'package:quickgrocery/core/startup/widgets/home_bootstrap_shimmer.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/auth/screens/customer_profile_add_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';

/// Root shell — splash → shimmer → home. Home never mounts before bootstrap.
class AppBootstrapShell extends ConsumerStatefulWidget {
  const AppBootstrapShell({super.key});

  @override
  ConsumerState<AppBootstrapShell> createState() => _AppBootstrapShellState();

  static void markOnboardingComplete(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppBootstrapShellState>();
    state?._onOnboardingComplete();
  }
}

class _AppBootstrapShellState extends ConsumerState<AppBootstrapShell> {
  String? _bootUid;
  bool _wasAuthenticated = false;
  String? _lastShellDestination;
  StreamSubscription<User?>? _authSubscription;

  void _logShellDestination(String destination) {
    if (_lastShellDestination == destination) return;
    _lastShellDestination = destination;
    PhoneAuthFlowLog.shellDestination(destination);
  }

  @override
  void initState() {
    super.initState();
    _wasAuthenticated = FirebaseAuth.instance.currentUser != null;
    AuthSignInCoordinator.signedInTick.addListener(_onPhoneSignInComplete);
    AuthSignOutCoordinator.signedOutTick.addListener(_onSignOutComplete);
    GuestAuthCoordinator.guestModeTick.addListener(_onGuestModeEntered);
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      PhoneAuthFlowLog.authStateChanged(
        uid: user?.uid,
        syncUid: FirebaseAuth.instance.currentUser?.uid,
      );
      // Firebase can emit a transient null while credentials are applied.
      if (user == null && FirebaseAuth.instance.currentUser != null) {
        PhoneAuthFlowLog.syncAuthIgnoredTransientNull();
        return;
      }
      final uid = user?.uid;
      if (uid != _bootUid) {
        unawaited(_syncAuth(force: uid == null));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_syncAuth()));
  }

  void _onPhoneSignInComplete() {
    if (!mounted) return;
    PhoneAuthFlowLog.navigation('coordinator tick — forcing syncAuth');
    unawaited(_syncAuth(force: true));
  }

  void _onSignOutComplete() {
    if (!mounted) return;
    PhoneAuthFlowLog.navigation('sign_out coordinator tick — forcing syncAuth');
    unawaited(_syncAuth(force: true));
  }

  void _onGuestModeEntered() {
    if (!mounted) return;
    unawaited(_syncGuest(force: true));
  }

  @override
  void dispose() {
    AuthSignInCoordinator.signedInTick.removeListener(_onPhoneSignInComplete);
    AuthSignOutCoordinator.signedOutTick.removeListener(_onSignOutComplete);
    GuestAuthCoordinator.guestModeTick.removeListener(_onGuestModeEntered);
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onOnboardingComplete() {
    ref.read(appBootstrapProvider.notifier).markOnboardingComplete();
    _bootUid = null;
    _syncAuth();
  }

  Future<void> _syncAuth({bool force = false}) async {
    final authAsync = ref.read(authUserProvider);
    final authUser = resolveAuthUser(authAsync);

    PhoneAuthFlowLog.syncAuthStarted(
      syncUid: FirebaseAuth.instance.currentUser?.uid,
      streamUid: authAsync.valueOrNull?.uid,
      bootUid: _bootUid,
    );

    if (!mounted) return;

    if (authUser == null) {
      if (FirebaseAuth.instance.currentUser != null) {
        PhoneAuthFlowLog.syncAuthIgnoredTransientNull();
        return;
      }
      _wasAuthenticated = false;
      _bootUid = null;

      await ref.read(guestSessionProvider.notifier).enable();
      await _syncGuest(force: force);
      return;
    }

    await ref.read(guestSessionProvider.notifier).disable();

    final signingInFresh = !_wasAuthenticated;
    _wasAuthenticated = true;

    if (!force &&
        _bootUid == authUser.uid &&
        ref.read(appBootstrapCompleteProvider) &&
        ref.read(appBootstrapProvider).status != AppBootstrapStatus.error) {
      if (signingInFresh) {
        await PhoneSignInNavigation.clearAuthRoutesWhenReady();
      }
      return;
    }

    _bootUid = authUser.uid;
    FloatingCartSuppression.reset();

    if (signingInFresh) {
      await PhoneSignInNavigation.clearAuthRoutesWhenReady();
    }

    if (!mounted) return;

    final deps = BootstrapDependencies(
      addressService: legacy.Provider.of<AddressService>(context, listen: false),
      categoryService:
          legacy.Provider.of<CategoryService>(context, listen: false),
      homeProvider: legacy.Provider.of<HomeProvider>(context, listen: false),
      deliveryZoneService:
          legacy.Provider.of<DeliveryZoneService>(context, listen: false),
    );

    await ref.read(appBootstrapProvider.notifier).runAuthenticated(
          deps,
          precacheImages: (snap) => HomeImagePrecache.warm(context, snap),
        );

    if (mounted && signingInFresh) {
      AuthSessionLog.homeNavigation(uid: authUser.uid);
    }
  }

  Future<void> _syncGuest({bool force = false}) async {
    if (!mounted) return;

    if (!force &&
        ref.read(appBootstrapCompleteProvider) &&
        ref.read(appBootstrapProvider).status != AppBootstrapStatus.error) {
      return;
    }

    FloatingCartSuppression.reset();

    final deps = BootstrapDependencies(
      addressService: legacy.Provider.of<AddressService>(context, listen: false),
      categoryService:
          legacy.Provider.of<CategoryService>(context, listen: false),
      homeProvider: legacy.Provider.of<HomeProvider>(context, listen: false),
      deliveryZoneService:
          legacy.Provider.of<DeliveryZoneService>(context, listen: false),
    );

    await ref.read(appBootstrapProvider.notifier).runGuest(
          deps,
          precacheImages: (snap) => HomeImagePrecache.warm(context, snap),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(appBootstrapProvider);
    final authUser = resolveAuthUser(ref.watch(authUserProvider));
    final isGuest = authUser == null;

    if (bootstrap.needsOnboarding && authUser != null) {
      _logShellDestination('CustomerDetailsAddScreen');
      return const CustomerDetailsAddScreen();
    }

    if (bootstrap.status == AppBootstrapStatus.error ||
        bootstrap.phase == AppBootstrapPhase.error) {
      _logShellDestination('BootstrapErrorScreen');
      final guestRetry = authUser == null && isGuest;
      return BootstrapErrorScreen(
        message: bootstrap.errorMessage ?? '',
        isRetrying: bootstrap.isRetrying,
        onRetry: () => ref
            .read(appBootstrapProvider.notifier)
            .retry(guest: guestRetry),
      );
    }

    switch (bootstrap.phase) {
      case AppBootstrapPhase.idle:
      case AppBootstrapPhase.splash:
        _logShellDestination('AppAnimatedSplash');
        return const AppAnimatedSplash();
      case AppBootstrapPhase.loadingHome:
        _logShellDestination('HomeBootstrapShimmer');
        return const HomeBootstrapShimmer();
      case AppBootstrapPhase.ready:
      case AppBootstrapPhase.degraded:
        _logShellDestination('LandingScreen');
        return const _ReadyHome();
      case AppBootstrapPhase.error:
        _logShellDestination('BootstrapErrorScreen');
        final guestRetry = authUser == null && isGuest;
        return BootstrapErrorScreen(
          message: bootstrap.errorMessage ?? '',
          isRetrying: bootstrap.isRetrying,
          onRetry: () => ref
              .read(appBootstrapProvider.notifier)
              .retry(guest: guestRetry),
        );
    }
  }
}

class _ReadyHome extends ConsumerStatefulWidget {
  const _ReadyHome();

  @override
  ConsumerState<_ReadyHome> createState() => _ReadyHomeState();
}

class _ReadyHomeState extends ConsumerState<_ReadyHome> {
  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.reset();
    HomeShellObserver.markReady();
    AppStartupLog.milestone('Home displayed');
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumePendingAction());
  }

  Future<void> _resumePendingAction() async {
    final action = GuestAuthCoordinator.consumePendingAction();
    if (action == GuestPostLoginAction.continueCheckout) {
      if (!appRouteObserver.isCurrent(AppRoutes.checkout)) {
        final nav = rootNavigatorKey.currentState;
        if (nav != null && nav.mounted) {
          nav.push(AppPageRoutes.checkout());
        }
      }
    }
    if (!mounted) return;
    await GuestAddressMigrator.discardPendingAfterLogin(ref);
  }

  @override
  Widget build(BuildContext context) => const LandingScreen();
}
