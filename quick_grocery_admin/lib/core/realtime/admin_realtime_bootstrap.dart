import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/orders/orders_navigation.dart';
import 'package:quick_grocery_admin/view/products/services/product_service.dart';

/// Starts global Firestore listeners once per admin session.
class AdminRealtimeBootstrap {
  AdminRealtimeBootstrap._();

  static bool _started = false;

  static void start(BuildContext context) {
    if (_started) return;
    _started = true;

    final products = context.read<ProductService>();
    products.ensureProductsListener();
    products.ensureCategoriesListener();
    products.ensureVendorsListener();

    context.read<DashBoardServices>().startRealtimeListeners();
    context.read<DeliveryBoyService>()
      ..ensureDeliveryBoysListener()
      ..ensureOrderStatsListener();

    syncOrderServiceForRoute(context, AdminRoutes.newOrders);
  }

  static void resetForTest() => _started = false;
}
