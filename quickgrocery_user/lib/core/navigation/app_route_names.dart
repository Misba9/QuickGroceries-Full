/// Named routes used for navigation and floating-cart visibility.
abstract final class AppRoutes {
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout-success';
  static const orderTracking = '/order-tracking';
  static const payment = '/payment';
  static const notifications = '/notifications';
  static const location = '/location';
  static const address = '/address';
  static const addAddress = '/add-address';
  static const search = '/search';
  static const product = '/product';
  static const comboDetail = '/combo-detail';
  static const login = '/login';
  static const otp = '/otp';
  static const splash = '/splash';
  static const home = '/home';

  /// [HomeProvider.pages] index for the profile tab.
  static const profileTabIndex = 4;

  /// [HomeProvider.pages] index for the grocery AI assistant tab.
  static const aiChatTabIndex = 3;

  /// Pushed full-screen orders list (no longer a bottom tab).
  static const ordersList = '/orders-list';

  @Deprecated('Orders is no longer a tab — use [aiChatTabIndex] or push orders list')
  static const ordersTabIndex = aiChatTabIndex;

  /// Screens where the floating cart bar must never appear.
  static const hiddenFromFloatingCart = {
    cart,
    checkout,
    checkoutSuccess,
    orderTracking,
    payment,
    notifications,
    location,
    address,
    addAddress,
    search,
    login,
    otp,
    splash,
    ordersList,
  };

  /// Pushed screens with a fixed bottom action bar — pill sits above it.
  static const routesWithBottomChrome = {
    product,
    comboDetail,
  };
}
