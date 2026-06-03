import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/widgets/global_floating_cart_widget.dart';
import 'package:quickgrocery/core/widgets/premium_five_tab_nav.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

/// Whether the global floating cart bar should render.
class GlobalCartVisibility {
  GlobalCartVisibility._();

  /// Height of a typical screen bottom bar (action + padding), above safe area.
  static const double screenBottomChrome = 88;

  static bool _isHiddenRoute(String? routeName) {
    if (routeName == null) return false;
    return AppRoutes.hiddenFromFloatingCart.contains(routeName);
  }

  static bool shouldShow(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return false;
    if (FloatingCartSuppression.isActive) return false;

    final routeName = appRouteObserver.topRouteName;
    if (_isHiddenRoute(routeName)) return false;

    final nav = rootNavigatorKey.currentState;
    final onRoot = nav != null && !nav.canPop();
    if (onRoot) {
      try {
        final tab =
            legacy.Provider.of<HomeProvider>(context, listen: false).selectedIndex;
        if (tab == AppRoutes.profileTabIndex) return false;
      } catch (_) {
        /* HomeProvider not in tree */
      }
    }

    return true;
  }

  /// Bottom offset placing the pill above tab bar, bottom chrome, or safe area.
  static double bottomOffset(BuildContext context) {
    final routeName = appRouteObserver.topRouteName;
    final nav = rootNavigatorKey.currentState;
    final onRoot = nav != null && !nav.canPop();
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    if (onRoot) {
      return PremiumFiveTabNav.floatingOverlayBodyBottom(context);
    }

    if (routeName != null &&
        AppRoutes.routesWithBottomChrome.contains(routeName)) {
      return screenBottomChrome + safeBottom + GlobalFloatingCartWidget.gapAboveTabBar;
    }

    return GlobalFloatingCartWidget.gapAboveTabBar + safeBottom;
  }
}
