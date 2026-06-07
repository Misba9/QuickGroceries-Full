import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'dart:developer' as developer;

import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/widgets/global_floating_cart_widget.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/global_cart_visibility.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

/// App-wide floating cart host — single overlay, no duplicates.
class GlobalCartOverlay extends ConsumerStatefulWidget {
  const GlobalCartOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalCartOverlay> createState() => _GlobalCartOverlayState();
}

class _GlobalCartOverlayState extends ConsumerState<GlobalCartOverlay> {
  static const bool _cartDiagLogs = true;

  void _trace(String message) {
    if (!_cartDiagLogs) return;
    developer.log(message, name: 'GlobalCartOverlay');
  }

  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.depthListenable.addListener(_rebuildOverlay);
    appRouteObserver.topRouteListenable.addListener(_rebuildOverlay);
  }

  @override
  void dispose() {
    FloatingCartSuppression.depthListenable.removeListener(_rebuildOverlay);
    appRouteObserver.topRouteListenable.removeListener(_rebuildOverlay);
    super.dispose();
  }

  void _rebuildOverlay() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    // Rebuild when the bottom-tab selection changes (e.g. profile).
    try {
      legacy.Provider.of<HomeProvider>(context, listen: true);
    } catch (_) {}

    final show = !cart.isEmpty && GlobalCartVisibility.shouldShow(context);
    final bottom = GlobalCartVisibility.bottomOffset(context);
    final inset = GlobalFloatingCartWidget.horizontalInset;
    _trace(
      'rebuild: show=$show items=${cart.items.length} units=${cart.totalUnits} total=${cart.bill.total.toStringAsFixed(2)}',
    );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        widget.child,
        if (show)
          Positioned(
            left: inset,
            right: inset,
            bottom: bottom,
            child: const GlobalFloatingCartWidget(),
          ),
      ],
    );
  }
}
