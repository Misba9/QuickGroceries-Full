import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';

/// Tracks the topmost named route for global UI (floating cart visibility).
final AppRouteObserver appRouteObserver = AppRouteObserver();

class AppRouteObserver extends NavigatorObserver {
  String? _topRouteName;

  String? get topRouteName => _topRouteName;

  /// Notifies [GlobalCartOverlay] and other listeners when the top route changes.
  final ValueNotifier<String?> topRouteListenable = ValueNotifier<String?>(null);

  bool isCurrent(String routeName) => _topRouteName == routeName;

  void _applyTopRouteName(String? name) {
    if (_topRouteName == name) return;
    _topRouteName = name;
    topRouteListenable.value = name;
    _reconcileSuppression(name);
  }

  /// Screen-level suppression was removed; reset if we land on a showable route.
  void _reconcileSuppression(String? routeName) {
    final hidden = routeName != null &&
        AppRoutes.hiddenFromFloatingCart.contains(routeName);
    if (!hidden && FloatingCartSuppression.isActive) {
      FloatingCartSuppression.reset();
    }
  }

  void _syncTop(Route<dynamic>? route) {
    _applyTopRouteName(route?.settings.name);
  }

  /// After [didPop], read the navigator's current route so the top name is never stale.
  void _syncTopFromNavigator(NavigatorState? navigator) {
    if (navigator == null) return;
    Route<dynamic>? current;
    navigator.popUntil((route) {
      if (route.isCurrent) current = route;
      return route.isCurrent;
    });
    _syncTop(current);
  }

  void _scheduleNavigatorSync(NavigatorState? navigator) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncTopFromNavigator(navigator);
    });
  }

  /// Ensures [topRouteName] matches the navigator on cold start (before any
  /// push/pop events fire on physical devices).
  void syncWithRootNavigator() {
    _syncTopFromNavigator(rootNavigatorKey.currentState);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _syncTop(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Sync immediately so the floating cart does not stay hidden (or visible
    // on the wrong screen) until the next frame — release builds on physical
    // devices are sensitive to this one-frame lag.
    if (previousRoute != null) {
      _syncTop(previousRoute);
    } else {
      _scheduleNavigatorSync(route.navigator);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute != null) {
      _syncTop(previousRoute);
    } else {
      _scheduleNavigatorSync(route.navigator);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _syncTop(newRoute);
    } else {
      _scheduleNavigatorSync(oldRoute?.navigator);
    }
  }
}
