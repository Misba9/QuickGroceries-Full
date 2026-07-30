/// Centralized Play / App Store listing URLs for the **Delivery** app.
class StoreLinks {
  const StoreLinks._();

  static const androidPackageId = 'com.quick_grocery_delivery.app';
  static const iosBundleId = 'com.example.quickGroceryDelivery';
  static const iosAppStoreId = '';

  static const android =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  static String ios({String? appStoreId}) {
    final id = (appStoreId ?? iosAppStoreId).trim();
    if (id.isEmpty) return 'https://apps.apple.com/app/id';
    return 'https://apps.apple.com/app/id$id';
  }
}
