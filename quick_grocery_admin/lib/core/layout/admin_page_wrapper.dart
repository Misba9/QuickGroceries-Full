import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/layout/admin_constraints.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/core/layout/admin_safe_page.dart';
import 'package:quick_grocery_admin/core/responsive/admin_content_scope.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';

/// Background for admin content panes.
const Color kAdminContentBackground = Color(0xFFFFFAF0);

/// Centered content with explicit height — safe inside scroll views.
class AdminBoundedCenter extends StatelessWidget {
  const AdminBoundedCenter({
    super.key,
    required this.child,
    this.minHeight = 240,
  });

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: Center(child: child),
    );
  }
}

/// Hosts the active admin route inside the dashboard shell.
///
/// - [flexLayout] false (default): one vertical scroll via [AdminSafePage].
/// - [flexLayout] true: bounded viewport for list screens ([Column] + [Expanded]).
class AdminPageSlot extends StatelessWidget {
  const AdminPageSlot({
    super.key,
    required this.route,
    required this.child,
    this.flexLayout = false,
    this.padding,
  });

  final String route;
  final Widget child;
  final bool flexLayout;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('AdminPageSlot: $route flex=$flexLayout');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 1200.0;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0;

        final pad = padding ??
            (flexLayout
                ? const EdgeInsets.all(20)
                : const EdgeInsets.all(24));

        final page = flexLayout
            ? AdminFlexPage(
                padding: pad,
                debugLabel: route,
                child: child,
              )
            : AdminSafePage(
                padding: pad,
                debugLabel: route,
                child: child,
              );

        return AdminContentScope(
          maxWidth: w,
          child: ColoredBox(
            color: kAdminContentBackground,
            child: SizedBox(
              width: w,
              height: h,
              child: page,
            ),
          ),
        );
      },
    );
  }
}

/// @deprecated Use [AdminSafePage] inside [AdminPageSlot] instead.
class AdminPageWrapper extends StatelessWidget {
  const AdminPageWrapper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.capContentWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? capContentWidth;

  @override
  Widget build(BuildContext context) {
    return AdminSafePage(
      padding: padding,
      child: ConstrainedBox(
        constraints: adminNormalizedConstraints(
          viewportWidth: capContentWidth ?? 1200,
        ),
        child: child,
      ),
    );
  }
}

/// White card shell for section content (scroll-safe).
class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Desktop / mobile shell: fixed sidebar + top bar + bounded content pane.
class AdminDashboardShell extends StatelessWidget {
  const AdminDashboardShell({
    super.key,
    required this.sidebar,
    required this.topBar,
    required this.body,
    this.scaffoldKey,
    this.drawer,
    this.useDrawerLayout = false,
    this.sidebarWidth = adminDesktopSidebarExpandedWidth,
  });

  final Widget sidebar;
  final Widget topBar;
  final Widget body;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? drawer;
  final bool useDrawerLayout;
  final double sidebarWidth;

  static const Color shellBackground = Color(0xFFF5F6FA);

  @override
  Widget build(BuildContext context) {
    final mainPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(color: kAdminContentBackground, child: topBar),
        Expanded(child: body),
      ],
    );

    if (useDrawerLayout) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: shellBackground,
        drawer: drawer,
        drawerEnableOpenDragGesture: true,
        body: SafeArea(child: mainPane),
      );
    }

    return Scaffold(
      backgroundColor: shellBackground,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: adminSidebarAnimationDuration,
              curve: Curves.easeInOutCubic,
              width: sidebarWidth,
              child: ClipRect(child: sidebar),
            ),
            VerticalDivider(width: 1, color: Colors.grey.shade200),
            Expanded(child: mainPane),
          ],
        ),
      ),
    );
  }
}

/// Routes that fill the viewport with [Column]/[Expanded] (no outer scroll).
abstract final class AdminFlexRoutes {
  static const Set<String> routes = {
    ...AdminRoutes.customerRoutes,
    AdminRoutes.vendorList,
    AdminRoutes.vendorRequests,
    AdminRoutes.deliveryBoyList,
    AdminRoutes.deliveryZones,
    AdminRoutes.deliverySettings,
    AdminRoutes.productList,
    AdminRoutes.notificationTemplates,
    AdminRoutes.notificationHistory,
    AdminRoutes.appContent,
    AdminRoutes.supportSettings,
    AdminRoutes.platformFee,
    AdminRoutes.maintenance,
    AdminRoutes.referEarn,
  };
}
