import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';
import 'package:quickgrocery/core/widgets/premium_five_tab_nav.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/global_cart_visibility.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

/// App-wide floating cart bar above all routes (except excluded screens).
class GlobalCartOverlay extends ConsumerWidget {
  const GlobalCartOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    legacy.Provider.of<HomeProvider?>(context, listen: true);

    final show = !cart.isEmpty && GlobalCartVisibility.shouldShow(context);
    final onRoot = !(rootNavigatorKey.currentState?.canPop() ?? false);
    final bottom = onRoot
        ? PremiumFiveTabNav.floatingOverlayBodyBottom(context)
        : GlobalCartVisibility.bottomOffset(context);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        child,
        if (show)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            child: const FloatingCartPill(),
          ),
      ],
    );
  }

}
