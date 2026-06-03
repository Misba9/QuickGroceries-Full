/// Named routes used for navigation and floating-cart visibility.
abstract final class AppRoutes {
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout-success';
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

  /// [HomeProvider.pages] index for the profile tab.
  static const profileTabIndex = 4;

  /// Screens where the floating cart bar must never appear.
  static const hiddenFromFloatingCart = {
    cart,
    checkout,
    checkoutSuccess,
    payment,
    notifications,
    location,
    address,
    addAddress,
    search,
    login,
    otp,
    splash,
  };

  /// Pushed screens with a fixed bottom action bar — pill sits above it.
  static const routesWithBottomChrome = {
    product,
    comboDetail,
  };
}
