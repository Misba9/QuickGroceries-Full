import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/navigation/home_shell_observer.dart';
import 'package:quickgrocery/core/navigation/home_tab_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/core/widgets/global_floating_cart_widget.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_bootstrap_state.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/global_cart_visibility.dart';

/// App-wide floating cart host — renders via a root [OverlayEntry] so the pill
/// stays above routes on cold start (Stack-in-builder is unreliable on physical
/// Android release builds before the first navigator sync).
class GlobalCartOverlay extends ConsumerStatefulWidget {
  const GlobalCartOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalCartOverlay> createState() => _GlobalCartOverlayState();
}

class _GlobalCartOverlayState extends ConsumerState<GlobalCartOverlay> {
  static const bool _cartDiagLogs = true;

  OverlayEntry? _entry;
  bool _externalListenersAttached = false;

  void _trace(String message) {
    if (!_cartDiagLogs) return;
    developer.log(message, name: 'GlobalCartOverlay');
  }

  @override
  void initState() {
    super.initState();
    AppStartupLog.log('GlobalCartOverlay mounted');
    _attachExternalListeners();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      appRouteObserver.syncWithRootNavigator();
      _ensureOverlayEntry();
    });
  }

  void _attachExternalListeners() {
    if (_externalListenersAttached) return;
    _externalListenersAttached = true;
    FloatingCartSuppression.depthListenable.addListener(_refreshOverlayEntry);
    appRouteObserver.topRouteListenable.addListener(_refreshOverlayEntry);
    HomeTabObserver.selectedIndexListenable.addListener(_refreshOverlayEntry);
    HomeShellObserver.readyTick.addListener(_refreshOverlayEntry);
  }

  void _detachExternalListeners() {
    if (!_externalListenersAttached) return;
    _externalListenersAttached = false;
    FloatingCartSuppression.depthListenable.removeListener(_refreshOverlayEntry);
    appRouteObserver.topRouteListenable.removeListener(_refreshOverlayEntry);
    HomeTabObserver.selectedIndexListenable.removeListener(_refreshOverlayEntry);
    HomeShellObserver.readyTick.removeListener(_refreshOverlayEntry);
  }

  void _refreshOverlayEntry() {
    _entry?.markNeedsBuild();
  }

  void _ensureOverlayEntry() {
    if (!mounted) return;
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _ensureOverlayEntry());
      return;
    }

    _entry ??= OverlayEntry(builder: _buildOverlayEntry);
    if (!_entry!.mounted) {
      overlay.insert(_entry!);
      AppStartupLog.log('Floating cart overlay entry inserted');
    }
    _entry!.markNeedsBuild();
  }

  bool _computeShow(BuildContext context) {
    final bootstrapComplete = ref.read(appBootstrapCompleteProvider);
    final cartReady = ref.read(cartBootstrapReadyProvider);
    if (!bootstrapComplete || !cartReady) return false;

    final cart = ref.read(cartProvider);
    final authAsync = ref.read(authUserProvider);
    final authUser = resolveAuthUser(authAsync);
    final authResolved = isAuthResolved(authAsync);

    return authResolved &&
        !cart.isEmpty &&
        GlobalCartVisibility.shouldShow(
          context,
          authUser: authUser,
          authResolved: authResolved,
        );
  }

  Widget _buildOverlayEntry(BuildContext context) {
    final cart = ref.read(cartProvider);
    final authAsync = ref.read(authUserProvider);
    final bootstrapReady = ref.read(cartBootstrapReadyProvider);
    final authUser = resolveAuthUser(authAsync);
    final authResolved = isAuthResolved(authAsync);
    final show = _computeShow(context);
    final bottom = GlobalCartVisibility.bottomOffset(context);
    final inset = GlobalFloatingCartWidget.horizontalInset;

    _trace(
      'overlay: show=$show bootstrap=$bootstrapReady authResolved=$authResolved '
      'authUid=${authUser?.uid} syncUid=${FirebaseAuth.instance.currentUser?.uid} '
      'items=${cart.items.length} units=${cart.totalUnits} '
      'route=${appRouteObserver.topRouteName} tab=${HomeTabObserver.selectedIndexListenable.value} '
      'suppression=${FloatingCartSuppression.depthListenable.value}',
    );

    if (show) {
      AppStartupLog.log('cart popup visible', 'units=${cart.totalUnits}');
    }

    if (!show) return const SizedBox.shrink();

    return Positioned(
      left: inset,
      right: inset,
      bottom: bottom,
      child: const GlobalFloatingCartWidget(),
    );
  }

  @override
  void dispose() {
    _detachExternalListeners();
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CartState>(cartProvider, (_, __) => _refreshOverlayEntry());
    ref.listen(authUserProvider, (_, __) => _refreshOverlayEntry());
    ref.listen(cartBootstrapReadyProvider, (_, __) => _refreshOverlayEntry());
    ref.listen(appBootstrapCompleteProvider, (_, __) => _refreshOverlayEntry());
    return widget.child;
  }
}
