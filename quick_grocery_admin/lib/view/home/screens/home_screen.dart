import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/add_banner.dart';
import 'package:quick_grocery_admin/view/coupon_screen.dart';
import 'package:quick_grocery_admin/view/delivery_boy/screens/add_delivery_boy.dart';
import 'package:quick_grocery_admin/view/platform_fee/screens/platform_fee_screen.dart';
import 'package:quick_grocery_admin/view/delivery_boy/screens/delivery_boy_list.dart';
import 'package:quick_grocery_admin/view/delivery_location/screens/delivery_location_list_screen.dart';
import 'package:quick_grocery_admin/view/delivery_settings/screens/delivery_settings_screen.dart';
import 'package:quick_grocery_admin/view/home/screens/dabshboard.dart';
import 'package:quick_grocery_admin/view/orders/screens/all_orders_screen.dart';
import 'package:quick_grocery_admin/view/orders/screens/cancelled_orders_screen.dart';
import 'package:quick_grocery_admin/view/orders/screens/delivered_orders_screen.dart';
import 'package:quick_grocery_admin/view/orders/screens/new_orders_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/add_category_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/add_subcategory_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/product_add_screen.dart';
import 'package:quick_grocery_admin/view/products/screens/product_list.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';
import 'package:quick_grocery_admin/view/users/screens/user_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_add_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:quick_grocery_admin/view/sms/presentation/screens/sms_history_screen.dart';
import 'package:quick_grocery_admin/view/sms/presentation/screens/sms_notifications_screen.dart';
import 'package:quick_grocery_admin/view/sms/presentation/screens/sms_templates_screen.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Provider.of<ProductService>(context, listen: false).fetchProducts();
  }

  String selectedScreen = "Dashboard";

  void _navigateTo(String subcategory, {bool closeDrawer = false}) {
    setState(() => selectedScreen = subcategory);
    if (closeDrawer) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Widget _sideMenu({required bool closeDrawerOnSelect}) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
            padding: EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Text(
              'MANAGEMENT',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/dashboard.svg',
            title: "Dashboard",
            subcategories: const ["Dashboard"],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/user.svg',
            title: "User",
            subcategories: const ["User List"],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/shop.svg',
            title: "Vendor",
            subcategories: const ["Vendor Add", "Vendor List"],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/cart.svg',
            title: "Orders",
            subcategories: const [
              "New Orders",
              "All Orders",
              "Cancelled Orders",
              "Delivered Orders",
            ],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/del.svg',
            title: "Delivery Boys",
            subcategories: const ["Add Delivery Boy", "Delivery Boy List"],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/location.svg',
            title: "Delivery Location",
            subcategories: const ["Delivery Zones"],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/chart.svg',
            title: "Platform Fee",
            subcategories: const [
              "Delivery Settings",
              "Platform Fee & Charges",
            ],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/box.svg',
            title: "Products",
            subcategories: const [
              "Product List",
              "Add Products",
              "Add Category",
              "Add Subcategory",
            ],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/image.svg',
            title: "Banner",
            subcategories: const ["Add Banner"],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/coupon.svg',
            title: "Coupon",
            subcategories: const ["Add Coupon"],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
          HoverExpansionTile(
            selectedSubcategory: selectedScreen,
            icon: 'assets/icons/sms.svg',
            title: "Notifications",
            subcategories: const [
              "SMS Notifications",
              "SMS Templates",
              "SMS History",
            ],
            onTap: (s) => _navigateTo(s, closeDrawer: closeDrawerOnSelect),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final compact = adminIsMobileWidth(w);
        final content = ColoredBox(
          color: const Color(0xFFFFFAF0),
          child: adminConstrainContentWidth(
            maxWidth: 1440,
            child: _getSelectedScreen(selectedScreen),
          ),
        );

        if (compact) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFFFFAF0),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColor.primary,
              title: const Text(
                'Quick Grocery Admin',
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            drawer: Drawer(
              width: adminSidebarWidth(w),
              child: _sideMenu(closeDrawerOnSelect: true),
            ),
            body: SafeArea(child: content),
          );
        }

        final sidebarW = adminSidebarWidth(w);
        return Scaffold(
          backgroundColor: const Color(0xFFFFFAF0),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: sidebarW,
                  child: _sideMenu(closeDrawerOnSelect: false),
                ),
                VerticalDivider(width: 1, color: Colors.grey.shade200),
                Expanded(child: content),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getSelectedScreen(String screen) {
    switch (screen) {
      case "Dashboard":
        return DashboardScreen();
      case "User List":
        return UsersScreen();
      case "Vendor Add":
        return VendorAddScreen();
      case "Vendor List":
        return VendorListScreen();
      case "New Orders":
        return NewOrdersScreeen();
      case "All Orders":
        return AllOrdersScreeen();
      case "Cancelled Orders":
        return CancelledOrdersScreeen();
      case "Delivered Orders":
        return DeliveredOrdersScreeen();
      case "Add Delivery Boy":
        return AddDeliveryScreen();
      case "Delivery Boy List":
        return DeliveryBoysScreen();
      case "Delivery Zones":
        return DeliveryLocationListScreen();
      case "Delivery Settings":
        return DeliverySettingsScreen();
      case "Product List":
        return ProductListScreen();
      case "Add Category":
        return AddCategoryScreen();
      case "Add Subcategory":
        return AddSubCategoryScreen();
      case "Add Products":
        return ProductAddScreen();
      case "Add Banner":
        return AddBannerScreen();
      case "Add Coupon":
        return CouponScreen();
      case "Platform Fee & Charges":
        return PlatformFeeScreen();
      case "SMS Notifications":
        return const SmsNotificationsScreen();
      case "SMS Templates":
        return const SmsTemplatesScreen();
      case "SMS History":
        return const SmsHistoryScreen();
      default:
        return Center(child: Text("Select a category"));
    }
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

class HoverExpansionTile extends StatefulWidget {
  final String icon;
  final String title;
  final List<String> subcategories;
  final Function(String) onTap;
  final String selectedSubcategory; // Add selectedSubcategory

  const HoverExpansionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subcategories,
    required this.onTap,
    required this.selectedSubcategory, // Pass selectedSubcategory
  });

  @override
  _HoverExpansionTileState createState() => _HoverExpansionTileState();
}

class _HoverExpansionTileState extends State<HoverExpansionTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            isHovered ? 12.0 : 0.0,
          ), // Adjust radius

          child: Material(
            color: isHovered ? Colors.grey.shade100 : Colors.transparent,
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16),
              leading: SvgPicture.asset(
                widget.icon,
                color: isHovered ? AppColor.primary : Colors.black,
              ),
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isHovered ? AppColor.primary : Colors.black,
                ),
              ),
              children: widget.subcategories.map((sub) {
                bool isSelected =
                    widget.selectedSubcategory == sub; // Check if selected
                return Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: ListTile(
                    leading: Container(
                      height: 5,
                      width: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primary : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColor.primary
                            : Colors.black, // Change color if selected
                      ),
                    ),
                    onTap: () {
                      widget.onTap(sub);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
