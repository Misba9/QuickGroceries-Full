import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/auth/phone_auth_coordinator.dart';
import 'package:quickgrocery/core/navigation/auth_floating_cart_guard.dart';
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
import 'package:quickgrocery/view/auth/screens/login_screen.dart';
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
  bool _syncInFlight = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null && FirebaseAuth.instance.currentUser != null) {
        return;
      }
      final uid = user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid != _bootUid) {
        _syncAuth();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAuth());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onOnboardingComplete() {
    ref.read(appBootstrapProvider.notifier).markOnboardingComplete();
    _bootUid = null;
    _syncAuth();
  }

  Future<void> _syncAuth() async {
    if (_syncInFlight) return;

    var authUser = resolveAuthUser(ref.read(authUserProvider));
    if (authUser == null && FirebaseAuth.instance.currentUser != null) {
      authUser = FirebaseAuth.instance.currentUser;
    }

    if (!mounted) return;

    if (authUser == null) {
      if (FirebaseAuth.instance.currentUser != null) return;
      _bootUid = null;
      PhoneAuthCoordinator.reset();
      ref.read(appBootstrapProvider.notifier).markSignedOut();
      return;
    }

    PhoneAuthCoordinator.clearAuthRoutes();

    if (_bootUid == authUser.uid &&
        ref.read(appBootstrapCompleteProvider) &&
        ref.read(appBootstrapProvider).status != AppBootstrapStatus.error) {
      return;
    }

    _syncInFlight = true;
    _bootUid = authUser.uid;
    FloatingCartSuppression.reset();

    final deps = BootstrapDependencies(
      addressService: legacy.Provider.of<AddressService>(context, listen: false),
      categoryService:
          legacy.Provider.of<CategoryService>(context, listen: false),
      homeProvider: legacy.Provider.of<HomeProvider>(context, listen: false),
      deliveryZoneService:
          legacy.Provider.of<DeliveryZoneService>(context, listen: false),
    );

    try {
      await ref.read(appBootstrapProvider.notifier).runAuthenticated(
            deps,
            precacheImages: (snap) => HomeImagePrecache.warm(context, snap),
          );
    } finally {
      _syncInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(appBootstrapProvider);
    final authUser =
        resolveAuthUser(ref.watch(authUserProvider)) ?? bootstrap.user;

    if (authUser == null) {
      return const AuthFloatingCartGuard(child: LoginScreen());
    }

    if (bootstrap.needsOnboarding) {
      return const CustomerDetailsAddScreen();
    }

    if (bootstrap.status == AppBootstrapStatus.error ||
        bootstrap.phase == AppBootstrapPhase.error) {
      return BootstrapErrorScreen(
        message: bootstrap.errorMessage ?? '',
        isRetrying: bootstrap.isRetrying,
        onRetry: () => ref.read(appBootstrapProvider.notifier).retry(),
      );
    }

    switch (bootstrap.phase) {
      case AppBootstrapPhase.idle:
      case AppBootstrapPhase.splash:
        return const AppAnimatedSplash();
      case AppBootstrapPhase.loadingHome:
        return const HomeBootstrapShimmer();
      case AppBootstrapPhase.ready:
      case AppBootstrapPhase.degraded:
        return const _ReadyHome();
      case AppBootstrapPhase.error:
        return BootstrapErrorScreen(
          message: bootstrap.errorMessage ?? '',
          isRetrying: bootstrap.isRetrying,
          onRetry: () => ref.read(appBootstrapProvider.notifier).retry(),
        );
    }
  }
}

class _ReadyHome extends StatefulWidget {
  const _ReadyHome();

  @override
  State<_ReadyHome> createState() => _ReadyHomeState();
}

class _ReadyHomeState extends State<_ReadyHome> {
  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.reset();
    HomeShellObserver.markReady();
    AppStartupLog.milestone('Home displayed');
  }

  @override
  Widget build(BuildContext context) => const LandingScreen();
}
