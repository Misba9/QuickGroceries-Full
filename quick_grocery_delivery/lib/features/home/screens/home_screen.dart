import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/account/account_screen.dart';
import 'package:quick_grocery_delivery/features/dashboard/driver_dashboard_page.dart';
import 'package:quick_grocery_delivery/features/orders/screens/order_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/wallet/wallet_screen.dart';
import 'package:quick_grocery_delivery/support/support_contact_sheet.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectIndex = 0;

  final _pages = const [
    DriverDashboardPage(),
    OrderScreen(),
    WalletScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notification.title}: ${notification.body}')),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final notification = message.notification;
      if (notification != null && mounted) {
        setState(() => _selectIndex = 1);
      }
    });

    Provider.of<OrderService>(context, listen: false).getDeliveryBoy();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);

    if (provider.deliveryBoy == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!provider.deliveryBoy!.isActive) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Image.asset('assets/icons/disable.png'),
                    ),
                    AppSpacing.h20,
                    const Text(
                      'Your account has been disabled',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    AppSpacing.h10,
                    const Text('Please contact support'),
                    AppSpacing.h15,
                    ElevatedButton.icon(
                      onPressed: () => SupportContactSheet.show(context),
                      icon: const Icon(Icons.support_agent_outlined),
                      label: const Text('Contact Support'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: GlobalVariables.background,
      body: _pages[_selectIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectIndex,
        onDestinationSelected: (i) => setState(() => _selectIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.delivery_dining_outlined), label: 'Orders'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}
