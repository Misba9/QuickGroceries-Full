import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/models/combo_offer_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/address/screens/add_address_screen.dart';
import 'package:quickgrocery/view/address/screens/address_screen.dart';
import 'package:quickgrocery/view/auth/screens/login_screen.dart';
import 'package:quickgrocery/view/auth/screens/otp_screen.dart';
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
import 'package:quickgrocery/core/navigation/auth_floating_cart_guard.dart';

/// Central factory for named routes with soft, grocery-app page transitions.
abstract final class AppPageRoutes {
  /// Platform Material push (checkout / payment — clear forward commitment).
  static MaterialPageRoute<T> material<T>({
    required String name,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<T>(
      settings: RouteSettings(name: name),
      builder: builder,
    );
  }

  /// Soft fade + micro-slide — Blinkit/Zepto browse feel.
  /// Opaque + no secondary underlay animation avoids route flicker at 60 FPS.
  static PageRoute<T> softSlide<T>({
    required String name,
    required WidgetBuilder builder,
    Duration duration = AppMotion.medium,
    Duration reverseDuration = AppMotion.short,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      opaque: true,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.emphasized,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route<void> cart() => softSlide(
        name: AppRoutes.cart,
        builder: (_) => const CartScreen(),
      );

  static Route<void> login() => softSlide(
        name: AppRoutes.login,
        builder: (_) => const AuthFloatingCartGuard(child: LoginScreen()),
      );

  static Route<void> otp() => softSlide(
        name: AppRoutes.otp,
        builder: (_) => const AuthFloatingCartGuard(child: OtpAuthScreen()),
      );

  static MaterialPageRoute<void> checkout() =>
      material(name: AppRoutes.checkout, builder: (_) => const CheckoutScreen());

  static Route<void> notifications() => softSlide(
        name: AppRoutes.notifications,
        builder: (_) => const NotificationCenterScreen(),
      );

  static Route<void> location() => softSlide(
        name: AppRoutes.location,
        builder: (_) => const LocationPicker(),
      );

  static Route<void> search() => softSlide(
        name: AppRoutes.search,
        builder: (_) => const SearchScreen(),
        duration: AppMotion.short,
      );

  static Route<void> product(
    ProductModel product, {
    String? heroTag,
  }) =>
      softSlide(
        name: AppRoutes.product,
        builder: (_) => ProductViewScreen(product: product, heroTag: heroTag),
      );

  static Route<void> comboDetail({
    required ComboOfferModel combo,
    bool addToCartOnLoad = false,
  }) =>
      softSlide(
        name: AppRoutes.comboDetail,
        builder: (_) => ComboDetailScreen(
          combo: combo,
          addToCartOnLoad: addToCartOnLoad,
        ),
      );

  static Route<void> address() => softSlide(
        name: AppRoutes.address,
        builder: (_) => const AddressScreen(),
      );

  static Route<bool> addAddress({AddressModel? editing}) => softSlide<bool>(
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

  static Route<void> orderTracking({
    required String orderId,
  }) =>
      softSlide(
        name: '${AppRoutes.orderTracking}/$orderId',
        builder: (_) => OrderTrackingScreen(orderId: orderId),
      );

  static Route<void> ordersList() => softSlide(
        name: AppRoutes.ordersList,
        builder: (_) => const OrdersScreeen(asPushedRoute: true),
      );
}
