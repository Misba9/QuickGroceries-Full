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
import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/permissions/app_permission_coordinator.dart';
import 'package:quickgrocery/core/push/fcm_push_initializer.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/startup/home_image_precache.dart';
import 'package:quickgrocery/core/startup/post_home_startup.dart';
import 'package:quickgrocery/core/startup/widgets/app_animated_splash.dart';
import 'package:quickgrocery/core/startup/widgets/bootstrap_error_screen.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/auth/screens/customer_profile_add_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';

/// Root shell — category animation → home. Home never mounts before bootstrap.
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
  bool _guestSyncInFlight = false;

  /// Keeps category-animation State alive across phase changes.
  final GlobalKey _splashKey = GlobalKey();

  /// Preserves Home State across splash underlay → solo mount.
  final GlobalKey _readyHomeKey = GlobalKey();

  /// Home is mounted under the splash during the exit crossfade.
  bool _homeUnderlayMounted = false;

  /// Splash removed after it fades out over Home (no black gap).
  bool _startupSplashDismissed = false;

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
    // Auth stream is observed once via [authUserProvider] in [build] —
    // avoids a second FirebaseAuth.authStateChanges() subscription.
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

    // Auth stream + signedOutTick both force-sync — only one guest boot.
    if (_guestSyncInFlight) return;
    _guestSyncInFlight = true;
    FloatingCartSuppression.reset();

    try {
      final deps = BootstrapDependencies(
        addressService:
            legacy.Provider.of<AddressService>(context, listen: false),
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
    } finally {
      _guestSyncInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Single auth subscription via Riverpod (shared with other authUser readers).
    ref.listen(authUserProvider, (prev, next) {
      if (!mounted) return;
      final user = resolveAuthUser(next);
      PhoneAuthFlowLog.authStateChanged(
        uid: user?.uid,
        syncUid: FirebaseAuth.instance.currentUser?.uid,
      );
      if (user == null && FirebaseAuth.instance.currentUser != null) {
        PhoneAuthFlowLog.syncAuthIgnoredTransientNull();
        return;
      }
      final uid = user?.uid;
      if (uid != _bootUid) {
        unawaited(_syncAuth(force: uid == null));
      }
    });

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
      case AppBootstrapPhase.loadingHome:
        _homeUnderlayMounted = false;
        _startupSplashDismissed = false;
        _logShellDestination('AppAnimatedSplash');
        return ColoredBox(
          color: kLaunchYellow,
          child: AppAnimatedSplash(
            key: _splashKey,
            appReady: false,
          ),
        );
      case AppBootstrapPhase.ready:
      case AppBootstrapPhase.degraded:
        // Keep looping categories until essential home content is present.
        final essentialReady = bootstrap.homeSnapshot.hasContent;

        if (_startupSplashDismissed) {
          _logShellDestination('LandingScreen');
          return ColoredBox(
            color: AppSurface.of(context).scaffold,
            child: _ReadyHome(key: _readyHomeKey),
          );
        }

        _logShellDestination(
          _homeUnderlayMounted ? 'RevealHome' : 'AppAnimatedSplash',
        );
        return ColoredBox(
          color: kLaunchYellow,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Home mounts under splash after the current category cycle ends.
              if (_homeUnderlayMounted) _ReadyHome(key: _readyHomeKey),
              AppAnimatedSplash(
                key: _splashKey,
                appReady: essentialReady,
                onReadyToOpenHome: () {
                  if (!mounted || _homeUnderlayMounted) return;
                  setState(() => _homeUnderlayMounted = true);
                },
                onExitComplete: () {
                  if (!mounted || _startupSplashDismissed) return;
                  setState(() => _startupSplashDismissed = true);
                },
              ),
            ],
          ),
        );
      case AppBootstrapPhase.error:
        _homeUnderlayMounted = false;
        _startupSplashDismissed = false;
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
  const _ReadyHome({super.key});

  @override
  ConsumerState<_ReadyHome> createState() => _ReadyHomeState();
}

class _ReadyHomeState extends ConsumerState<_ReadyHome>
    with SingleTickerProviderStateMixin {
  AnimationController? _permissionSettle;

  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.reset();
    HomeShellObserver.markReady();
    AppStartupLog.milestone('Home displayed');
    PostHomeStartup.scheduleAfterHomeVisible();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resumePendingAction());
      _schedulePermissionsAfterHomeReady();
    });
  }

  void _schedulePermissionsAfterHomeReady() {
    // Frame-synced settle using AnimationController — no Timer / delayed.
    _permissionSettle?.dispose();
    final settle = AnimationController(
      vsync: this,
      duration: LoadingConstants.homeEnterFade +
          LoadingConstants.permissionPromptSettle,
    );
    _permissionSettle = settle;
    settle.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      unawaited(_requestPermissionsNow());
    });
    settle.forward();
  }

  Future<void> _requestPermissionsNow() async {
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    AppStartupLog.milestone('Requesting OS permissions (post-home)');
    await AppPermissionCoordinator.requestAfterAppReady(
      requestIosLocalNotifications:
          FcmPushInitializer.requestIosLocalNotificationPermission,
    );
  }

  @override
  void dispose() {
    _permissionSettle?.dispose();
    super.dispose();
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
    await consumePendingPushNavigation();
  }

  @override
  Widget build(BuildContext context) {
    // Full opacity immediately — splash crossfades away over this layer.
    return const LandingScreen();
  }
}
