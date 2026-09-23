import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Centralized responsive helper.
///
/// Use [Responsive.of] to query the device class, [productGridColumnsForWidth]
/// for product grids, and [horizontalInset] for page gutters (including a
/// max content width on large iPads).
class Responsive {
  Responsive._(this.width);

  final double width;

  static Responsive of(BuildContext context) =>
      Responsive._(MediaQuery.sizeOf(context).width);

  static const double productGridSpacing = 12;

  bool get isPhone => width < AppBreakpoints.tablet;
  bool get isTablet =>
      width >= AppBreakpoints.tablet && width < AppBreakpoints.desktop;
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

  /// Gutter that also centers content when the window is wider than
  /// [AppBreakpoints.contentMaxWidth].
  double horizontalInset() {
    final g = gutter();
    if (width <= AppBreakpoints.contentMaxWidth) return g;
    return math.max(g, (width - AppBreakpoints.contentMaxWidth) / 2);
  }

  /// Product columns for this screen width (after caller subtracts padding
  /// if they pass a pane width into [productGridColumnsForWidth]).
  int productGridColumns() => productGridColumnsForWidth(width);

  /// Column count from **available** width (pane, not device model).
  ///
  /// `<600` → 2 · `600–899` → 3 · `900–1199` → 4 · `1200+` → 5,
  /// capped so each tile stays ≥ [AppBreakpoints.productMinCardWidth].
  static int productGridColumnsForWidth(double availableWidth) {
    if (availableWidth <= 0) return 2;
    final byBreakpoints = availableWidth < AppBreakpoints.tablet
        ? 2
        : availableWidth < AppBreakpoints.largeTablet
            ? 3
            : availableWidth < AppBreakpoints.xl
                ? 4
                : 5;
    final byMinWidth = ((availableWidth + productGridSpacing) /
            (AppBreakpoints.productMinCardWidth + productGridSpacing))
        .floor()
        .clamp(2, 5);
    return math.min(byBreakpoints, byMinWidth).clamp(2, 5);
  }

  /// Taller cells when Dynamic Type or 2-column phone layouts need room
  /// for Phase 3 type (2-line name, weight, rating, 40pt ADD).
  static double productCardAspectRatio(
    BuildContext context, {
    required int columns,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
    final base = columns >= 4 ? 0.62 : (columns == 3 ? 0.58 : 0.56);
    return (base / scale.clamp(1.0, 1.85)).clamp(0.46, 0.70);
  }

  static SliverGridDelegate productGridDelegate(
    BuildContext context, {
    required double availableWidth,
    double spacing = productGridSpacing,
  }) {
    final cols = productGridColumnsForWidth(availableWidth);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: spacing,
      mainAxisSpacing: 10,
      childAspectRatio: productCardAspectRatio(context, columns: cols),
    );
  }

  /// Horizontal [HomeProductCard] rails — scales with screen height and
  /// inversely with text scale so cards never bottom-overflow.
  static double horizontalProductRailHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textFactor = (mq.textScaler.scale(12) / 12).clamp(0.82, 1.65);
    return ((mq.size.height * 0.318) / textFactor).clamp(248.0, 328.0);
  }

  /// Compact rail for "Order again" tiles (image + title + CTA).
  static double orderAgainRailHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textFactor = (mq.textScaler.scale(11) / 11).clamp(0.82, 1.6);
    return (204 / textFactor).clamp(176.0, 236.0);
  }

  /// Cart horizontal product rail height (matches [HomeProductCard]).
  static double legacyHorizontalProductRailHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textFactor = (mq.textScaler.scale(12) / 12).clamp(0.82, 1.65);
    return ((mq.size.height * 0.31) / textFactor).clamp(252.0, 332.0);
  }
}
