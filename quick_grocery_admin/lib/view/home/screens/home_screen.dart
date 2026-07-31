import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/core/layout/admin_sidebar_prefs.dart';

export 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/add_banner.dart';
import 'package:quick_grocery_admin/view/app_content_management/screens/app_content_management_screen.dart';
import 'package:quick_grocery_admin/view/combo_offers/screens/combo_offers_screen.dart';
import 'package:quick_grocery_admin/view/coupons/screens/coupon_management_screen.dart';
import 'package:quick_grocery_admin/view/product_promotions/screens/product_promotions_screen.dart';
import 'package:quick_grocery_admin/view/search_analytics/screens/search_analytics_screen.dart';
import 'package:quick_grocery_admin/view/app_heatmap/screens/app_heatmap_screen.dart';
import 'package:quick_grocery_admin/view/refer_earn/screens/refer_earn_management_screen.dart';
import 'package:quick_grocery_admin/view/delivery_tips/screens/delivery_tips_management_screen.dart';
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
import 'package:quick_grocery_admin/view/ai_chat/screens/ai_chat_inbox_screen.dart';
import 'package:quick_grocery_admin/view/payment_settings/screens/payment_settings_screen.dart';
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
  bool _sidebarCollapsed = false;

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
    _loadSidebarPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AdminRealtimeBootstrap.start(context);
      syncOrderServiceForRoute(context, _selectedScreen);
      syncCustomerServiceForRoute(context, _selectedScreen);
    });
  }

  Future<void> _loadSidebarPrefs() async {
    final collapsed = await AdminSidebarPrefs.loadCollapsed();
    if (!mounted) return;
    setState(() => _sidebarCollapsed = collapsed);
  }

  Future<void> _toggleSidebarCollapsed() async {
    final next = !_sidebarCollapsed;
    setState(() => _sidebarCollapsed = next);
    await AdminSidebarPrefs.saveCollapsed(next);
  }

  /// Screen bodies only — [AdminPageSlot] is wrapped in [_activePage] so
  /// [AdminFlexRoutes] changes apply without a full app restart.
  List<Widget> _buildPages() {
    return [
      const DashboardScreen(),
      for (final r in AdminRoutes.customerRoutes) customerPageForRoute(r),
      VendorAddScreen(),
      VendorListScreen(),
      const VendorRequestsScreen(),
      const OrdersOverviewScreen(),
      const NewOrdersScreen(),
      const ManageOrdersScreen(),
      const RefundRequestsScreen(),
      AddDeliveryScreen(),
      DeliveryBoysScreen(),
      DeliveryLocationListScreen(),
      DeliverySettingsScreen(),
      ProductListScreen(),
      AddCategoryScreen(),
      AddSubCategoryScreen(),
      ProductAddScreen(),
      const ReviewManagementScreen(),
      const ReviewAnalyticsScreen(),
      const AddBannerScreen(),
      const CouponManagementScreen(),
      const ComboOffersScreen(),
      const ProductPromotionsScreen(),
      const SearchAnalyticsScreen(),
      const AppHeatmapScreen(),
      const ReferEarnManagementScreen(),
      const DeliveryTipsManagementScreen(),
      PlatformFeeScreen(),
      const PushNotificationsScreen(),
      const NotificationTemplatesScreen(),
      const NotificationHistoryScreen(),
      const AppContentManagementScreen(),
      const SupportSettingsScreen(),
      const AiChatInboxScreen(),
      const PaymentSettingsScreen(),
      const MaintenanceManagementScreen(),
    ];
  }

  int get _selectedIndex => _routeIndex[_selectedScreen] ?? 0;

  Widget _activePage() {
    final i = _selectedIndex;
    final route = AdminRoutes.all[i];
    final body = _pageCache.putIfAbsent(i, () => _pages[i]);
    return AdminPageSlot(
      key: PageStorageKey<String>(route),
      route: route,
      flexLayout: AdminFlexRoutes.routes.contains(route),
      child: body,
    );
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
    final useDrawer = adminUsesDrawerLayout(width);
    final isDesktop = !useDrawer;
    final sidebarWidth = isDesktop
        ? adminDesktopSidebarWidthFor(collapsed: _sidebarCollapsed)
        : adminSidebarWidth(width);

    final sidebar = AdminSidebar(
      width: sidebarWidth,
      collapsed: isDesktop && _sidebarCollapsed,
      selectedRoute: _selectedScreen,
      onSelect: useDrawer
          ? (r) => _navigateTo(r, closeDrawer: true)
          : _navigateTo,
    );

    return AdminDashboardShell(
      scaffoldKey: _scaffoldKey,
      useDrawerLayout: useDrawer,
      sidebarWidth: sidebarWidth,
      drawer: Drawer(
        width: adminSidebarWidth(width),
        child: SafeArea(child: sidebar),
      ),
      sidebar: sidebar,
      topBar: AdminGlobalTopBar(
        title: _selectedScreen,
        leading: IconButton(
          icon: Icon(
            isDesktop && !_sidebarCollapsed
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            color: AppColor.primary,
          ),
          tooltip: isDesktop
              ? (_sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar')
              : 'Open menu',
          onPressed: () {
            if (isDesktop) {
              _toggleSidebarCollapsed();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
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
