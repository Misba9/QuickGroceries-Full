import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/core/widgets/admin_nav_item.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';

/// Fixed-width scrollable admin sidebar (Flutter Web safe, explicit hit targets).
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.selectedRoute,
    required this.onSelect,
    this.width = adminDesktopSidebarWidth,
  });

  final String selectedRoute;
  final ValueChanged<String> onSelect;
  final double width;

  static final _sections = <_SectionDef>[
    _SectionDef(
      icon: 'assets/icons/dashboard.svg',
      title: 'Dashboard',
      routes: [AdminRoutes.dashboard],
    ),
    _SectionDef(
      icon: 'assets/icons/user.svg',
      title: 'User',
      routes: [AdminRoutes.userList],
    ),
    _SectionDef(
      icon: 'assets/icons/shop.svg',
      title: 'Vendor',
      routes: [AdminRoutes.vendorAdd, AdminRoutes.vendorList, AdminRoutes.vendorRequests],
    ),
    _SectionDef(
      icon: 'assets/icons/cart.svg',
      title: 'Orders',
      routes: [
        AdminRoutes.ordersOverview,
        AdminRoutes.newOrders,
        AdminRoutes.manageOrders,
        AdminRoutes.refundRequests,
      ],
    ),
    _SectionDef(
      icon: 'assets/icons/del.svg',
      title: 'Delivery Boys',
      routes: [AdminRoutes.addDeliveryBoy, AdminRoutes.deliveryBoyList],
    ),
    _SectionDef(
      icon: 'assets/icons/location.svg',
      title: 'Delivery Location',
      routes: [AdminRoutes.deliveryZones],
    ),
    _SectionDef(
      icon: 'assets/icons/chart.svg',
      title: 'Platform Fee',
      routes: [AdminRoutes.deliverySettings, AdminRoutes.platformFee],
    ),
    _SectionDef(
      icon: 'assets/icons/box.svg',
      title: 'Products',
      routes: [
        AdminRoutes.productList,
        AdminRoutes.addProducts,
        AdminRoutes.addCategory,
        AdminRoutes.addSubcategory,
        AdminRoutes.reviewManagement,
        AdminRoutes.reviewAnalytics,
      ],
    ),
    _SectionDef(
      icon: 'assets/icons/image.svg',
      title: 'Banner',
      routes: [AdminRoutes.addBanner],
    ),
    _SectionDef(
      icon: 'assets/icons/coupon.svg',
      title: 'Coupon',
      routes: [AdminRoutes.addCoupon, AdminRoutes.comboOffers],
    ),
    _SectionDef(
      icon: 'assets/icons/sms.svg',
      title: 'Push Notifications',
      routes: [
        AdminRoutes.pushNotifications,
        AdminRoutes.notificationTemplates,
        AdminRoutes.notificationHistory,
      ],
    ),
    _SectionDef(
      icon: 'assets/icons/user.svg',
      title: 'Settings',
      routes: [
        AdminRoutes.appContent,
        AdminRoutes.supportSettings,
        AdminRoutes.maintenance,
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          right: false,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 4, 12),
                child: Text(
                  'Quick Grocery',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    color: AppColor.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'MANAGEMENT',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final section in _sections)
                _SidebarSection(
                  key: ValueKey(section.title),
                  def: section,
                  selectedRoute: selectedRoute,
                  onSelect: onSelect,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDef {
  const _SectionDef({
    required this.icon,
    required this.title,
    required this.routes,
  });

  final String icon;
  final String title;
  final List<String> routes;
}

class _SidebarSection extends StatefulWidget {
  const _SidebarSection({
    super.key,
    required this.def,
    required this.selectedRoute,
    required this.onSelect,
  });

  final _SectionDef def;
  final String selectedRoute;
  final ValueChanged<String> onSelect;

  @override
  State<_SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<_SidebarSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.def.routes.contains(widget.selectedRoute);
  }

  @override
  void didUpdateWidget(_SidebarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.def.routes.contains(widget.selectedRoute)) {
      _expanded = true;
    }
  }

  Widget _sectionIcon({required bool active}) {
    return SvgPicture.asset(
      widget.def.icon,
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(
        active ? AppColor.primary : Colors.black87,
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionActive = widget.def.routes.contains(widget.selectedRoute);

    if (widget.def.routes.length == 1) {
      final route = widget.def.routes.first;
      final badge = route == AdminRoutes.dashboard
          ? context.watch<AdminNotificationService>().unreadCount
          : 0;
      return AdminNavItem(
        label: widget.def.title,
        selected: widget.selectedRoute == route,
        icon: _sectionIcon(active: sectionActive),
        onTap: () => widget.onSelect(route),
        height: 52,
        badgeCount: badge,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _sectionIcon(active: sectionActive),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.def.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: sectionActive
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: sectionActive
                              ? AppColor.primary
                              : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 22,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded)
          ...widget.def.routes.map(
            (route) => AdminNavItem(
              label: route,
              selected: widget.selectedRoute == route,
              leadingDot: true,
              indent: 12,
              height: 44,
              onTap: () => widget.onSelect(route),
            ),
          ),
      ],
    );
  }
}
