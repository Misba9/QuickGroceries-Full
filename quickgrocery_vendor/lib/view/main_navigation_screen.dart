import 'package:flutter/material.dart';
import '../models/vendor_model.dart';
import '../style/app_color.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'products/products_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final VendorModel vendor;

  const MainNavigationScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  VendorModel? _currentVendor;

  @override
  void initState() {
    super.initState();
    _currentVendor = widget.vendor;
  }

  void _updateVendor(VendorModel updatedVendor) {
    setState(() {
      _currentVendor = updatedVendor;
    });
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColor.primary,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentVendor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Use IndexedStack to maintain state of each screen
    // Each screen has its own Scaffold with bottomNavigationBar
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeScreen(),
        _buildOrdersScreen(),
        _buildProductsScreen(),
        _buildProfileScreen(),
      ],
    );
  }

  Widget _buildHomeScreen() {
    return HomeScreen(
      vendor: _currentVendor!,
      onNavigateToOrders: () => setState(() => _currentIndex = 1),
      onNavigateToProducts: () => setState(() => _currentIndex = 2),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildOrdersScreen() {
    return OrdersScreen(
      vendor: _currentVendor!,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProductsScreen() {
    return ProductsScreen(
      vendor: _currentVendor!,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProfileScreen() {
    return ProfileScreen(
      vendor: _currentVendor!,
      onVendorUpdated: _updateVendor,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}


