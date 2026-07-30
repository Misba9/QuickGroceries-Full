import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/view/customers/navigation/customers_navigation.dart';
import 'package:quick_grocery_admin/view/customers/screens/customer_list_screen.dart';
import 'package:quick_grocery_admin/view/customers/screens/payment_restrictions_screen.dart';

/// Customer sidebar routes — list segments or Payment Restrictions page.
Widget customerPageForRoute(String route) {
  if (route == AdminRoutes.paymentRestrictions) {
    return const PaymentRestrictionsScreen();
  }
  return CustomerListScreen(segment: segmentForRoute(route));
}
