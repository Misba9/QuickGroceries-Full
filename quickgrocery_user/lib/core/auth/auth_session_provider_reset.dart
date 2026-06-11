import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/realtime/providers/realtime_providers.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_bootstrap_state.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/checkout_controller.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/home/presentation/providers/explore_products_provider.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/recently_viewed_provider.dart';
import 'package:quickgrocery/view/profile/presentation/providers/profile_providers.dart';

/// Invalidates user-scoped Riverpod state so the next account starts clean.
abstract final class AuthSessionProviderReset {
  /// Synchronous prep before Firebase [signOut]. Does not invalidate
  /// [cartProvider] or [authUserProvider] — those are handled after sign-out
  /// to avoid recreating cart/auth listeners mid-teardown.
  static void prepareForSignOut(WidgetRef ref) {
    ref.read(cartBootstrapReadyProvider.notifier).state = false;
    ref.read(deliveryZoneServiceProvider.notifier).state = null;
    ref.read(appBootstrapProvider.notifier).markSignedOut();
  }

  /// Drop cached user streams after Firebase session is gone.
  static void invalidateUserProviders(WidgetRef ref) {
    ref.invalidate(checkoutControllerProvider);
    ref.invalidate(userOrdersStreamProvider);
    ref.invalidate(customerProfileStreamProvider);
    ref.invalidate(wishlistCountProvider);
    ref.invalidate(addressCountProvider);
    ref.invalidate(userAddressesStreamProvider);
    ref.invalidate(orderCountsProvider);
    ref.invalidate(exploreProductsProvider);
    ref.invalidate(recentlyViewedIdsProvider);
    ref.invalidate(recentlyViewedProductsProvider);
    ref.invalidate(couponsStreamProvider);
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentUidProvider);
    ref.invalidate(ordersStreamProvider);
    ref.invalidate(notificationsStreamProvider);
    ref.invalidate(unreadNotificationsCountProvider);
  }
}
