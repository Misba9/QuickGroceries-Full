import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Breakpoints for Flutter Web admin (Shopify / Blinkit–style dashboards).
class AdminBreakpoints {
  AdminBreakpoints._();

  /// Handset / narrow browser
  static const double mobile = 600;

  /// Laptop range
  static const double desktop = 1024;
}

bool adminIsMobileWidth(double width) => width < AdminBreakpoints.mobile;

bool adminIsTabletWidth(double width) =>
    width >= AdminBreakpoints.mobile && width < AdminBreakpoints.desktop;

bool adminIsDesktopWidth(double width) => width >= AdminBreakpoints.desktop;

double adminResponsivePadding(double width) {
  if (width < AdminBreakpoints.mobile) return 12;
  if (width < AdminBreakpoints.desktop) return 16;
  return 24;
}

double adminResponsiveFontSize(
  double width, {
  required double mobile,
  required double tablet,
  required double desktop,
}) {
  if (width < AdminBreakpoints.mobile) return mobile;
  if (width < AdminBreakpoints.desktop) return tablet;
  return desktop;
}

int adminResponsiveGridCount(double width) {
  if (width < AdminBreakpoints.mobile) return 1;
  if (width < AdminBreakpoints.desktop) return 2;
  return 3;
}

double adminSidebarWidth(double screenWidth) {
  if (screenWidth < AdminBreakpoints.mobile) {
    return math.min(288, screenWidth * 0.88);
  }
  return (screenWidth * 0.18).clamp(200.0, 280.0);
}

/// Optional max width for main content on ultra-wide monitors.
Widget adminConstrainContentWidth({
  required Widget child,
  double maxWidth = 1280,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Layout bucket for [ResponsiveLayout] (mobile / tablet / desktop).
enum AdminLayoutSize {
  mobile,
  tablet,
  desktop,
}

AdminLayoutSize adminLayoutSizeForWidth(double width) {
  if (width < AdminBreakpoints.mobile) return AdminLayoutSize.mobile;
  if (width < AdminBreakpoints.desktop) return AdminLayoutSize.tablet;
  return AdminLayoutSize.desktop;
}

/// Standard [LayoutBuilder] wrapper with breakpoint helpers.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    AdminLayoutSize size,
    double maxWidth,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return builder(context, adminLayoutSizeForWidth(w), w);
      },
    );
  }
}

/// Horizontal scroll for wide [DataTable]s inside a bounded viewport.
Widget adminScrollableDataTable({
  required double viewportWidth,
  required DataTable dataTable,
  double minTableWidth = 880,
}) {
  final minW = math.max(viewportWidth, minTableWidth);
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: minW),
      child: dataTable,
    ),
  );
}
