import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/screens/orders_management_screen.dart';
import 'package:flutter/material.dart';

class AllOrdersScreeen extends StatelessWidget {
  const AllOrdersScreeen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrdersManagementScreen(preset: OrderListPreset.all);
  }
}
