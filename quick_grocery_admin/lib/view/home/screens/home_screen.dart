import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/add_banner.dart';
import 'package:quick_grocery_admin/view/coupon_screen.dart';
import 'package:quick_grocery_admin/view/delivery_boy/screens/add_delivery_boy.dart';
import 'package:quick_grocery_admin/view/platform_fee/screens/platform_fee_screen.dart';
import 'package:quick_grocery_admin/view/delivery_boy/screens/delivery_boy_list.dart';
import 'package:quick_grocery_admin/view/delivery_location/screens/delivery_location_list_screen.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    Provider.of<ProductService>(context, listen: false).fetchProducts();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String selectedScreen = "Dashboard";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Row(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  'Quick Grocery',
                  style: TextStyle(
                    fontSize: 30,
                    color: AppColor.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                height: MediaQuery.of(context).size.height * .90,
                width: MediaQuery.of(context).size.width * .18,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
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
                      subcategories: ["Dashboard"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    // User Category
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/user.svg',
                      title: "User",
                      subcategories: ["User List"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    // Vendor Category
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/shop.svg',
                      title: "Vendor",
                      subcategories: ["Vendor Add", "Vendor List"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    // Orders Category
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/cart.svg',
                      title: "Orders",
                      subcategories: [
                        "New Orders",
                        "All Orders",
                        "Cancelled Orders",
                        "Delivered Orders",
                      ],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    // Delivery Boys Category
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/del.svg',
                      title: "Delivery Boys",
                      subcategories: ["Add Delivery Boy", "Delivery Boy List"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    // Delivery Location Category
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/location.svg',
                      title: "Delivery Location",
                      subcategories: ["Delivery Zones"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/box.svg',
                      title: "Products",
                      subcategories: [
                        "Product List",
                        "Add Products",
                        "Add Category",
                        "Add Subcategory",
                      ],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/image.svg',
                      title: "Banner",
                      subcategories: ["Add Banner"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/coupon.svg',
                      title: "Coupon",
                      subcategories: ["Add Coupon"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                    HoverExpansionTile(
                      selectedSubcategory: selectedScreen,
                      icon: 'assets/icons/chart.svg',
                      title: "Platform Fee",
                      subcategories: ["Platform Fee and Charges"],
                      onTap: (String subcategory) {
                        setState(() {
                          selectedScreen = subcategory;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          VerticalDivider(color: Colors.grey.shade200),
          Expanded(child: _getSelectedScreen(selectedScreen)),
        ],
      ),
    );
  } // Function to return the selected screen

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
      case "Platform Fee and Charges":
        return PlatformFeeScreen();
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
    return Row(
      children: [
        Text('$label :'),
        AppSpacing.w10,
        Text(value, style: TextStyle(fontSize: 16)),
      ],
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
