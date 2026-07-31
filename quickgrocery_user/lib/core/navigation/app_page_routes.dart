import 'package:flutter/material.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/models/combo_offer_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/address/screens/add_address_screen.dart';
import 'package:quickgrocery/view/address/screens/address_screen.dart';
import 'package:quickgrocery/view/cart/presentation/screens/checkout_screen.dart';
import 'package:quickgrocery/view/cart/screen/cart_screen.dart';
import 'package:quickgrocery/view/combo/presentation/screens/combo_detail_screen.dart';
import 'package:quickgrocery/view/home/screens/location_selector.dart';
import 'package:quickgrocery/view/notifications/notification_center_screen.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:quickgrocery/view/orders/presentation/screens/orders_screen.dart';
import 'package:quickgrocery/view/payment/screens/payment_screen.dart';
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';
import 'package:quickgrocery/view/search/screens/search_screen.dart';

/// Central factory for named [MaterialPageRoute]s.
abstract final class AppPageRoutes {
  static MaterialPageRoute<T> material<T>({
    required String name,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<T>(
      settings: RouteSettings(name: name),
      builder: builder,
    );
  }

  static MaterialPageRoute<void> cart() =>
      material(name: AppRoutes.cart, builder: (_) => const CartScreen());

  static MaterialPageRoute<void> checkout() =>
      material(name: AppRoutes.checkout, builder: (_) => const CheckoutScreen());

  static MaterialPageRoute<void> notifications() => material(
        name: AppRoutes.notifications,
        builder: (_) => const NotificationCenterScreen(),
      );

  static MaterialPageRoute<void> location() =>
      material(name: AppRoutes.location, builder: (_) => const LocationPicker());

  static MaterialPageRoute<void> search() =>
      material(name: AppRoutes.search, builder: (_) => const SearchScreen());

  static MaterialPageRoute<void> product(
    ProductModel product, {
    String? heroTag,
  }) =>
      material(
        name: AppRoutes.product,
        builder: (_) => ProductViewScreen(product: product, heroTag: heroTag),
      );

  static MaterialPageRoute<void> comboDetail({
    required ComboOfferModel combo,
    bool addToCartOnLoad = false,
  }) =>
      material(
        name: AppRoutes.comboDetail,
        builder: (_) => ComboDetailScreen(
          combo: combo,
          addToCartOnLoad: addToCartOnLoad,
        ),
      );

  static MaterialPageRoute<void> address() =>
      material(name: AppRoutes.address, builder: (_) => const AddressScreen());

  static MaterialPageRoute<bool> addAddress({AddressModel? editing}) =>
      material<bool>(
        name: AppRoutes.addAddress,
        builder: (_) => AddAdressScreen(editing: editing),
      );

  static MaterialPageRoute<void> payment() =>
      material(name: AppRoutes.payment, builder: (_) => const PaymentScreen());

  static MaterialPageRoute<void> checkoutSuccess({
    required String orderId,
  }) =>
      material(
        name: AppRoutes.checkoutSuccess,
        builder: (_) => OrderTrackingScreen(
          orderId: orderId,
          fromCheckout: true,
        ),
      );

  static MaterialPageRoute<void> orderTracking({
    required String orderId,
  }) =>
      material(
        name: '${AppRoutes.orderTracking}/$orderId',
        builder: (_) => OrderTrackingScreen(orderId: orderId),
      );

  static MaterialPageRoute<void> ordersList() => material(
        name: AppRoutes.ordersList,
        builder: (_) => const OrdersScreeen(asPushedRoute: true),
      );
}
