import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_segment.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

bool isCustomersRoute(String route) => AdminRoutes.customerRoutes.contains(route);

CustomerSegment segmentForRoute(String route) =>
    CustomerSegmentX.fromRoute(route) ?? CustomerSegment.allCustomers;

void syncCustomerServiceForRoute(BuildContext context, String route) {
  if (!isCustomersRoute(route)) return;
  if (route == AdminRoutes.paymentRestrictions) return;
  context.read<CustomerAdminService>().setSegment(segmentForRoute(route));
}
