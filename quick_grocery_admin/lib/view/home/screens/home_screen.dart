import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';

export 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/add_banner.dart';
import 'package:quick_grocery_admin/view/app_content_management/screens/app_content_management_screen.dart';
import 'package:quick_grocery_admin/view/combo_offers/screens/combo_offers_screen.dart';
import 'package:quick_grocery_admin/view/coupons/screens/coupon_management_screen.dart';
import 'package:quick_grocery_admin/view/delivery_boy/screens/add_delivery_boy.dart';
import 'package:quick_grocery_admin/view/delivery_boy/screens/delivery_boy_list.dart';
import 'package:quick_grocery_admin/view/delivery_location/screens/delivery_location_list_screen.dart';
import 'package:quick_grocery_admin/view/delivery_settings/screens/delivery_settings_screen.dart';
import 'package:quick_grocery_admin/view/home/screens/dabshboard.dart';
import 'package:quick_grocery_admin/view/home/widgets/admin_global_top_bar.dart';
import 'package:quick_grocery_admin/view/home/widgets/admin_sidebar.dart';
import 'package:quick_grocery_admin/view/maintenance/screens/maintenance_management_screen.dart';
import 'package:quick_grocery_admin/view/customers/customers_pages.dart';
import 'package:quick_grocery_admin/view/customers/navigation/customers_navigation.dart';
import 'package:quick_grocery_admin/view/orders/orders_navigation.dart';
import 'package:quick_grocery_admin/view/orders/screens/manage_orders_screen.dart';
import 'package:quick_grocery_admin/view/orders/screens/new_orders_screen.dart';
import 'package:quick_grocery_admin/view/orders/screens/orders_overview_screen.dart';
import 'package:quick_grocery_admin/view/orders/screens/refund_requests_screen.dart';
import 'package:quick_grocery_admin/view/platform_fee/screens/platform_fee_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/add_category_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/add_subcategory_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/product_add_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/product_list.dart';
import 'package:quick_grocery_admin/core/realtime/admin_realtime_bootstrap.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/screens/notification_history_screen.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/screens/notification_templates_screen.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/screens/push_notifications_screen.dart';
import 'package:quick_grocery_admin/view/reviews/screens/review_analytics_screen.dart';
import 'package:quick_grocery_admin/view/reviews/screens/review_management_screen.dart';
import 'package:quick_grocery_admin/view/support_settings/screens/support_settings_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_add_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_requests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedScreen = AdminRoutes.dashboard;
  late final List<Widget> _pages;
  late final Map<String, int> _routeIndex;

  /// Only the active route is laid out — avoids [IndexedStack] laying out all pages.
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    if (!AdminRoutes.all.contains(_selectedScreen)) {
      _selectedScreen = AdminRoutes.dashboard;
    }
    _routeIndex = {
      for (var i = 0; i < AdminRoutes.all.length; i++) AdminRoutes.all[i]: i,
    };
    _pages = _buildPages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AdminRealtimeBootstrap.start(context);
      syncOrderServiceForRoute(context, _selectedScreen);
      syncCustomerServiceForRoute(context, _selectedScreen);
    });
  }

  List<Widget> _buildPages() {
    Widget slot(String route, Widget child) => AdminPageSlot(
          key: PageStorageKey<String>(route),
          route: route,
          flexLayout: AdminFlexRoutes.routes.contains(route),
          child: child,
        );

    return [
      slot(AdminRoutes.dashboard, const DashboardScreen()),
      for (final r in AdminRoutes.customerRoutes)
        slot(r, customerPageForRoute(r)),
      slot(AdminRoutes.vendorAdd, VendorAddScreen()),
      slot(AdminRoutes.vendorList, VendorListScreen()),
      slot(AdminRoutes.vendorRequests, const VendorRequestsScreen()),
      slot(AdminRoutes.ordersOverview, const OrdersOverviewScreen()),
      slot(AdminRoutes.newOrders, const NewOrdersScreen()),
      slot(AdminRoutes.manageOrders, const ManageOrdersScreen()),
      slot(AdminRoutes.refundRequests, const RefundRequestsScreen()),
      slot(AdminRoutes.addDeliveryBoy, AddDeliveryScreen()),
      slot(AdminRoutes.deliveryBoyList, DeliveryBoysScreen()),
      slot(AdminRoutes.deliveryZones, DeliveryLocationListScreen()),
      slot(AdminRoutes.deliverySettings, DeliverySettingsScreen()),
      slot(AdminRoutes.productList, ProductListScreen()),
      slot(AdminRoutes.addCategory, AddCategoryScreen()),
      slot(AdminRoutes.addSubcategory, AddSubCategoryScreen()),
      slot(AdminRoutes.addProducts, ProductAddScreen()),
      slot(AdminRoutes.reviewManagement, const ReviewManagementScreen()),
      slot(AdminRoutes.reviewAnalytics, const ReviewAnalyticsScreen()),
      slot(AdminRoutes.addBanner, const AddBannerScreen()),
      slot(AdminRoutes.addCoupon, const CouponManagementScreen()),
      slot(AdminRoutes.comboOffers, const ComboOffersScreen()),
      slot(AdminRoutes.platformFee, PlatformFeeScreen()),
      slot(AdminRoutes.pushNotifications, const PushNotificationsScreen()),
      slot(AdminRoutes.notificationTemplates, const NotificationTemplatesScreen()),
      slot(AdminRoutes.notificationHistory, const NotificationHistoryScreen()),
      slot(AdminRoutes.appContent, const AppContentManagementScreen()),
      slot(AdminRoutes.supportSettings, const SupportSettingsScreen()),
      slot(AdminRoutes.maintenance, const MaintenanceManagementScreen()),
    ];
  }

  int get _selectedIndex => _routeIndex[_selectedScreen] ?? 0;

  Widget _activePage() {
    final i = _selectedIndex;
    return _pageCache.putIfAbsent(i, () => _pages[i]);
  }

  void _navigateTo(String route, {bool closeDrawer = false}) {
    if (!_routeIndex.containsKey(route)) {
      route = AdminRoutes.dashboard;
    }
    if (_selectedScreen == route) {
      if (closeDrawer) _scaffoldKey.currentState?.closeDrawer();
      return;
    }
    _pageCache.remove(_routeIndex[AdminRoutes.dashboard]);
    if (isOrdersRoute(_selectedScreen) || isOrdersRoute(route)) {
      for (final r in [
        AdminRoutes.ordersOverview,
        AdminRoutes.newOrders,
        AdminRoutes.manageOrders,
        AdminRoutes.refundRequests,
      ]) {
        final idx = _routeIndex[r];
        if (idx != null) _pageCache.remove(idx);
      }
    }
    if (isCustomersRoute(_selectedScreen) || isCustomersRoute(route)) {
      for (final r in AdminRoutes.customerRoutes) {
        final idx = _routeIndex[r];
        if (idx != null) _pageCache.remove(idx);
      }
    }
    syncOrderServiceForRoute(context, route);
    syncCustomerServiceForRoute(context, route);
    setState(() => _selectedScreen = route);
    if (closeDrawer) _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = adminIsMobileWidth(width);

    return AdminDashboardShell(
      scaffoldKey: _scaffoldKey,
      compact: compact,
      drawer: Drawer(
        width: adminSidebarWidth(width),
        child: SafeArea(
          child: AdminSidebar(
            width: adminSidebarWidth(width),
            selectedRoute: _selectedScreen,
            onSelect: (r) => _navigateTo(r, closeDrawer: true),
          ),
        ),
      ),
      sidebar: AdminSidebar(
        selectedRoute: _selectedScreen,
        onSelect: _navigateTo,
      ),
      topBar: AdminGlobalTopBar(
        title: _selectedScreen,
        leading: compact
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                color: AppColor.primary,
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
      ),
      body: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _activePage(),
      ),
    );
  }
}

class NamedFieldWidget extends StatelessWidget {
  const NamedFieldWidget({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          AppSpacing.w10,
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
