import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

/// Routes where the floating cart bar must not appear.
const Set<String> kGlobalCartHiddenRouteNames = {
  '/cart',
  '/checkout',
  '/login',
  '/otp',
  '/splash',
  '/checkout-success',
};

/// Whether the global cart pill should render for the current navigation state.
class GlobalCartVisibility {
  GlobalCartVisibility._();

  static bool shouldShow(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return false;

    final nav = rootNavigatorKey.currentState;
    if (nav == null) return false;

    final route = nav.overlay?.context != null
        ? ModalRoute.of(rootNavigatorKey.currentContext!)
        : null;
    final routeName = route?.settings.name;
    if (routeName != null && kGlobalCartHiddenRouteNames.contains(routeName)) {
      return false;
    }

    // Root [LandingScreen]: hide on Profile tab (index 4).
    final onRoot = !nav.canPop();
    if (onRoot) {
      try {
        final home = legacy.Provider.of<HomeProvider>(context, listen: false);
        if (home.selectedIndex == 4) return false;
      } catch (_) {
        // HomeProvider not in tree (e.g. during tests).
      }
      return true;
    }

    // Pushed shopping routes: show unless explicitly excluded by name.
    return routeName == null ||
        !kGlobalCartHiddenRouteNames.contains(routeName);
  }

  /// Bottom offset for the pill above safe area / tab bar.
  static double bottomOffset(BuildContext context) {
    final nav = rootNavigatorKey.currentState;
    final onRoot = nav != null && !nav.canPop();
    if (onRoot) {
      return 12; // [PremiumFiveTabNav.floatingOverlayBodyBottom] band
    }
    return 12 + MediaQuery.paddingOf(context).bottom;
  }
}
