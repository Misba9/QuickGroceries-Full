import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/navigation/home_tab_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/core/widgets/global_floating_cart_widget.dart';
import 'package:quickgrocery/core/widgets/premium_five_tab_nav.dart';

/// Whether the global floating cart bar should render.
class GlobalCartVisibility {
  GlobalCartVisibility._();

  static const bool _cartDiagLogs = true;

  static void _trace(String message) {
    if (!_cartDiagLogs) return;
    developer.log(message, name: 'GlobalCartVisibility');
  }

  /// Height of a typical screen bottom bar (action + padding), above safe area.
  static const double screenBottomChrome = 88;

  static bool _isHiddenRoute(String? routeName) {
    if (routeName == null) return false;
    return AppRoutes.hiddenFromFloatingCart.contains(routeName);
  }

  static bool shouldShow(
    BuildContext context, {
    required User? authUser,
    required bool authResolved,
  }) {
    if (!authResolved) {
      _trace('hidden: auth stream loading');
      return false;
    }
    if (authUser == null) {
      _trace('hidden: signed out');
      return false;
    }
    if (FloatingCartSuppression.isActive) {
      _trace('hidden: suppression depth=${FloatingCartSuppression.depthListenable.value}');
      return false;
    }

    final routeName = appRouteObserver.topRouteName;
    if (_isHiddenRoute(routeName)) {
      _trace('hidden: route=$routeName');
      return false;
    }

    final nav = rootNavigatorKey.currentState;
    final onRoot = nav != null && !nav.canPop();
    if (onRoot) {
      final tab = HomeTabObserver.selectedIndexListenable.value;
      if (tab == AppRoutes.profileTabIndex) {
        _trace('hidden: profile tab');
        return false;
      }
    }

    _trace('visible: route=$routeName onRoot=$onRoot tab=${HomeTabObserver.selectedIndexListenable.value}');
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
