/// Centralized Play / App Store listing URLs for the **User** app.
class StoreLinks {
  const StoreLinks._();

  static const androidPackageId = 'com.quickgrocery.io';
  static const iosBundleId = 'com.ahmed.quickgrocery';

  /// Optional numeric App Store id — leave empty to resolve via iTunes lookup.
  static const iosAppStoreId = '';

  static const android =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// Prefer [iosAppStoreId] when known; otherwise constructed after lookup.
  static String ios({String? appStoreId}) {
    final id = (appStoreId ?? iosAppStoreId).trim();
    if (id.isEmpty) {
      return 'https://apps.apple.com/app/id'; // filled at runtime after lookup
    }
    return 'https://apps.apple.com/app/id$id';
  }
}
