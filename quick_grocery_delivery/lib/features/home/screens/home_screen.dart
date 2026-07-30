import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/core/navigation/root_back_handler.dart';
import 'package:quick_grocery_delivery/core/delivery_notification_router.dart';
import 'package:quick_grocery_delivery/core/delivery_push_initializer.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/account/account_screen.dart';
import 'package:quick_grocery_delivery/features/dashboard/driver_dashboard_page.dart';
import 'package:quick_grocery_delivery/features/orders/screens/order_screen.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/wallet/wallet_screen.dart';
import 'package:quick_grocery_delivery/features/login/login_screen.dart';
import 'package:quick_grocery_delivery/features/login/services/login_service.dart';
import 'package:quick_grocery_delivery/services/driver_location_host.dart';
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
    // Foreground receive still uses sound callbacks; taps go through the router.
    DeliveryPushInitializer.onAssignmentPush = _onAssignmentPushForeground;
    DeliveryPushInitializer.onCancellationPush = _onCancellationBanner;

    DeliveryNotificationRouter.register(
      onSelectTab: (index) {
        if (!mounted) return;
        setState(() => _selectIndex = index);
      },
      onCancellationBanner: _onCancellationBanner,
    );

    final orders = Provider.of<OrderService>(context, listen: false);
    orders.getDeliveryBoy().then((_) => orders.startRealtimeOrders());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeliveryNotificationRouter.consumePending();
    });
  }

  void _onCancellationBanner(Map<String, dynamic> data) {
    if (!mounted) return;
    final orderId = data['orderId']?.toString() ?? '';
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.red.shade50,
        leading: const Icon(Icons.cancel, color: Colors.red),
        content: Text(
          orderId.isNotEmpty
              ? '❌ Delivery Cancelled\nOrder #${orderId.substring(0, 8)} was cancelled.'
              : '❌ Delivery Cancelled',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    context.read<OrderService>().startRealtimeOrders();
  }

  /// Foreground push arrival (not a tap) — refresh offers + light tab switch.
  void _onAssignmentPushForeground(Map<String, dynamic> data) {
    if (!mounted) return;
    final type = data['type']?.toString() ?? '';
    if (type == 'delivery_assigned' || type == 'driver_assigned') {
      setState(() => _selectIndex = 1);
      context.read<OrderService>().startRealtimeOrders();
    }
  }

  @override
  void dispose() {
    DeliveryPushInitializer.onAssignmentPush = null;
    DeliveryPushInitializer.onCancellationPush = null;
    DeliveryNotificationRouter.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);

    if (provider.deliveryBoy == null) {
      if (provider.profileLoadFailed) {
        return RootBackHandler(
          child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  AppSpacing.h20,
                  const Text(
                    'Could not load delivery profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.h10,
                  const Text(
                    'Your account may not be synced yet. Try again or sign in again.',
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.h20,
                  ElevatedButton(
                    onPressed: () => provider.getDeliveryBoy(),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await context.read<LoginService>().logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!provider.deliveryBoy!.isActive) {
      return RootBackHandler(
        child: Scaffold(
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
      ),
      );
    }

    return RootBackHandler(
      selectedTabIndex: _selectIndex,
      onTabSelected: (index) => setState(() => _selectIndex = index),
      child: DriverLocationHost(
        child: Scaffold(
        backgroundColor: GlobalVariables.background,
        body: _pages[_selectIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectIndex,
          onDestinationSelected: (i) => setState(() => _selectIndex = i),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
            NavigationDestination(
              icon: provider.pendingAssignmentCount > 0
                  ? Badge(
                      label: Text('${provider.pendingAssignmentCount}'),
                      child: const Icon(Icons.delivery_dining_outlined),
                    )
                  : const Icon(Icons.delivery_dining_outlined),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Wallet',
            ),
            const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ),
      ),
    );
  }
}
