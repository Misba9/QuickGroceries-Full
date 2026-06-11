import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/cart/services/cart_service.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/orders/services/order_service.dart';
import 'package:quickgrocery/view/payment/services/payment_service.dart';
import 'package:quickgrocery/view/product_view/services/product_view_service.dart';
import 'package:quickgrocery/view/profile/services/profile_service.dart';
import 'package:quickgrocery/view/search/services/search_service.dart';
import 'package:quickgrocery/view/tracking/services/tracking_service.dart';
import 'package:quickgrocery/view/wishlist/services/wishlist_service.dart';

/// Legacy [Provider] services reset during logout.
class SessionLegacyServices {
  const SessionLegacyServices({
    required this.auth,
    required this.address,
    required this.home,
    required this.category,
    required this.deliveryZone,
    required this.cart,
    required this.orders,
    required this.wishlist,
    required this.search,
    required this.productView,
    required this.payment,
    required this.tracking,
    required this.profile,
  });

  final AuthService auth;
  final AddressService address;
  final HomeProvider home;
  final CategoryService category;
  final DeliveryZoneService deliveryZone;
  final CartService cart;
  final OrderService orders;
  final WishlistService wishlist;
  final SearchService search;
  final ProductViewService productView;
  final PaymentService payment;
  final TrackingService tracking;
  final ProfileService profile;

  factory SessionLegacyServices.fromContext(BuildContext context) {
    return SessionLegacyServices(
      auth: context.read<AuthService>(),
      address: context.read<AddressService>(),
      home: context.read<HomeProvider>(),
      category: context.read<CategoryService>(),
      deliveryZone: context.read<DeliveryZoneService>(),
      cart: context.read<CartService>(),
      orders: context.read<OrderService>(),
      wishlist: context.read<WishlistService>(),
      search: context.read<SearchService>(),
      productView: context.read<ProductViewService>(),
      payment: context.read<PaymentService>(),
      tracking: context.read<TrackingService>(),
      profile: context.read<ProfileService>(),
    );
  }

  void resetInMemoryState() {
    auth.resetSessionForLogout();
    address.resetSessionForLogout();
    home.resetSessionForLogout();
    category.resetSessionForLogout();
    deliveryZone.invalidateCache();
    cart.resetSessionForLogout();
    orders.resetSessionForLogout();
    wishlist.resetSessionForLogout();
    search.resetSessionForLogout();
    productView.resetSessionForLogout();
    payment.resetSessionForLogout();
    tracking.resetSessionForLogout();
  }
}
