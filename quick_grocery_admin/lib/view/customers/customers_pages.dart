import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/customers/navigation/customers_navigation.dart';
import 'package:quick_grocery_admin/view/customers/screens/customer_list_screen.dart';

/// All customer sidebar routes use the same screen (segment set via navigation).
Widget customerPageForRoute(String route) {
  return CustomerListScreen(segment: segmentForRoute(route));
}
