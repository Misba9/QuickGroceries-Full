import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/view/orders/models/order_list_preset.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';

/// Syncs [OrderService] list mode when sidebar route changes.
void syncOrderServiceForRoute(BuildContext context, String route) {
  final svc = context.read<OrderService>();
  switch (route) {
    case AdminRoutes.newOrders:
      svc.setModulePage(OrderModulePage.newOrders);
      break;
    case AdminRoutes.manageOrders:
      svc.setModulePage(OrderModulePage.manage);
      svc.setQuickFilter(OrderQuickFilter.allOrders);
      break;
    case AdminRoutes.refundRequests:
      svc.setModulePage(OrderModulePage.refund);
      break;
    default:
      break;
  }
}

bool isOrdersRoute(String route) =>
    route == AdminRoutes.ordersOverview ||
    route == AdminRoutes.newOrders ||
    route == AdminRoutes.manageOrders ||
    route == AdminRoutes.refundRequests;
