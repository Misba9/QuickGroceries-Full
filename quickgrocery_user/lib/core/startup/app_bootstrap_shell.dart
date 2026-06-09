import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/auth/auth_user_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAuth());
  }

  void _onOnboardingComplete() {
    ref.read(appBootstrapProvider.notifier).markOnboardingComplete();
    _bootUid = null;
    _syncAuth();
  }

  Future<void> _syncAuth() async {
    final authUser = ref.read(authUserProvider).valueOrNull ??
        FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (authUser == null) {
      _bootUid = null;
      ref.read(appBootstrapProvider.notifier).markSignedOut();
      return;
    }

    if (_bootUid == authUser.uid &&
        ref.read(appBootstrapCompleteProvider) &&
        ref.read(appBootstrapProvider).status != AppBootstrapStatus.error) {
      return;
    }

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

    await ref.read(appBootstrapProvider.notifier).runAuthenticated(
          deps,
          precacheImages: (snap) => HomeImagePrecache.warm(context, snap),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (prev, next) {
      final uid = next.valueOrNull?.uid;
      if (uid != _bootUid) {
        _syncAuth();
      }
    });

    final bootstrap = ref.watch(appBootstrapProvider);
    final authUser =
        ref.watch(authUserProvider).valueOrNull ?? bootstrap.user;

    if (authUser == null) {
      return const LoginScreen();
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
