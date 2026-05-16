import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Centralized responsive helper.
///
/// Use [Responsive.of] to query the device class, [Responsive.cols] to
/// pick a column count for grids, and [Responsive.gutter] for horizontal
/// padding that scales with width. The breakpoints come from
/// [AppBreakpoints].
class Responsive {
  Responsive._(this.width);

  final double width;

  static Responsive of(BuildContext context) =>
      Responsive._(MediaQuery.sizeOf(context).width);

  bool get isPhone => width < AppBreakpoints.tablet;
  bool get isTablet => width >= AppBreakpoints.tablet && width < AppBreakpoints.desktop;
  bool get isDesktop => width >= AppBreakpoints.desktop;

  /// Picks a column count for a grid section.
  /// `phone`, `tablet`, `desktop` defaults match Zepto's behavior.
  int cols({int phone = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return phone;
  }

  /// Categories grid follows a tighter ramp.
  int categoryCols() => cols(phone: 4, tablet: 6, desktop: 8);

  /// Horizontal screen gutter — grows on tablets so content doesn't span
  /// full width on a 10" iPad.
  double gutter() {
    if (isDesktop) return 64;
    if (isTablet) return 32;
    return 16;
  }

  /// Horizontal [HomeProductCard] rails — scales with screen height and
  /// inversely with text scale so cards never bottom-overflow.
  static double horizontalProductRailHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textFactor = (mq.textScaler.scale(12) / 12).clamp(0.82, 1.65);
    return ((mq.size.height * 0.302) / textFactor).clamp(224.0, 306.0);
  }

  /// Compact rail for "Order again" tiles (image + title + CTA).
  static double orderAgainRailHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textFactor = (mq.textScaler.scale(11) / 11).clamp(0.82, 1.6);
    return (188 / textFactor).clamp(162.0, 216.0);
  }

  /// Cart horizontal product rail height (matches [HomeProductCard]).
  static double legacyHorizontalProductRailHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textFactor = (mq.textScaler.scale(12) / 12).clamp(0.82, 1.65);
    return ((mq.size.height * 0.295) / textFactor).clamp(232.0, 310.0);
  }
}
