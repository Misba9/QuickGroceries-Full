import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/responsive/admin_content_scope.dart';

/// Breakpoints for Flutter Web admin (Shopify / Blinkit–style dashboards).
class AdminBreakpoints {
  AdminBreakpoints._();

  /// Handset / narrow browser (< 900px uses drawer layout)
  static const double mobile = 900;

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

/// Expanded desktop rail (240–260px).
const double adminDesktopSidebarExpandedWidth = 252;

/// Collapsed desktop rail (icons only).
const double adminDesktopSidebarCollapsedWidth = 72;

/// @deprecated Use [adminDesktopSidebarExpandedWidth].
const double adminDesktopSidebarWidth = adminDesktopSidebarExpandedWidth;

const Duration adminSidebarAnimationDuration = Duration(milliseconds: 250);

/// Drawer overlay for handset + tablet; icon rail collapse on desktop.
bool adminUsesDrawerLayout(double screenWidth) =>
    screenWidth < AdminBreakpoints.desktop;

double adminDesktopSidebarWidthFor({required bool collapsed}) =>
    collapsed ? adminDesktopSidebarCollapsedWidth : adminDesktopSidebarExpandedWidth;

double adminSidebarWidth(double screenWidth) {
  if (screenWidth < AdminBreakpoints.mobile) {
    return math.min(288, screenWidth * 0.88);
  }
  return adminDesktopSidebarExpandedWidth;
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

/// Bounded viewport for legacy call sites (home shell uses [AdminPageSlot]).
Widget adminRouteBody({required Widget child}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 1200.0;
      final h = constraints.maxHeight;
      return AdminContentScope(
        maxWidth: w,
        child: SizedBox(
          width: w,
          height: h.isFinite ? h : null,
          child: child,
        ),
      );
    },
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
