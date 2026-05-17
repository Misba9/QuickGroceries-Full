import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/orders/tabs/cancel_order.dart';
import 'package:quick_grocery_delivery/features/orders/tabs/new_order.dart';
import 'package:quick_grocery_delivery/features/orders/tabs/transist_screen.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:quick_grocery_delivery/widgets/driver_empty_state.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().getOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalVariables.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Orders',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: GlobalVariables.primary,
              labelColor: GlobalVariables.primary,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Accepted'),
                Tab(text: 'Picked'),
                Tab(text: 'Delivered'),
                Tab(text: 'Cancelled'),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<OrderService>().getOrders(),
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    NewOrderTab(),
                    _AcceptedTab(),
                    TransistScreen(),
                    CompletedOrderScreen(),
                    _CancelledTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedTab extends StatelessWidget {
  const _AcceptedTab();

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>().myAcceptedOrders;
    if (orders.isEmpty) {
      return const DriverEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No accepted orders',
        subtitle: 'Accept pending offers from the dashboard',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderListTile(order: orders[i]),
    );
  }
}

class _CancelledTab extends StatelessWidget {
  const _CancelledTab();

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderService>().myCancelledOrders;
    if (orders.isEmpty) {
      return const DriverEmptyState(
        icon: Icons.cancel_outlined,
        title: 'No cancelled orders',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderListTile(order: orders[i]),
    );
  }
}

class _OrderListTile extends StatelessWidget {
  const _OrderListTile({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(order.customerName),
        subtitle: Text('${order.orderStatus} · ${order.address}'),
        trailing: Text('#${order.id.length > 6 ? order.id.substring(0, 6) : order.id}'),
      ),
    );
  }
}
