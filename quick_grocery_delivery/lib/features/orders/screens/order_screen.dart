import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:quick_grocery_delivery/features/orders/tabs/cancel_order.dart';
import 'package:quick_grocery_delivery/features/orders/tabs/new_order.dart';
import 'package:quick_grocery_delivery/features/orders/tabs/transist_screen.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    Provider.of<OrderService>(context, listen: false).getOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TabController tabController = TabController(length: 3, vsync: this);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                const Text(
                  'Orders',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TabBar(
                  indicatorWeight: 3,
                  labelPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  labelColor: GlobalVariables.primary,
                  unselectedLabelColor: Colors.grey.shade400,
                  controller: tabController,
                  indicatorColor: GlobalVariables.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Text('New'),
                    Text('In Transist'),
                    Text('Delivered'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: const [
                      NewOrderTab(),
                      TransistScreen(),
                      CompletedOrderScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
