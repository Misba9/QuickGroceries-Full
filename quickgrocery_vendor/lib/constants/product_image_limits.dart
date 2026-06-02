class ProductImageLimits {
  ProductImageLimits._();

  static const int minImages = 1;
  static const int maxImages = 8;
  static const int maxFileBytes = 5 * 1024 * 1024; // 5 MB

  /// Minimum dimensions (Firebase / Play Store quality).
  static const int minWidth = 500;
  static const int minHeight = 500;

  /// Recommended upload size for sharp PDP display.
  static const int recommendedWidth = 1000;
  static const int recommendedHeight = 1000;

  static const int pickQuality = 82;
  static const int maxWidth = 1200;
  static const int maxHeight = 1200;
  static const int thumbMaxSize = 400;

  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  static bool isAllowedExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return allowedExtensions.contains(ext);
  }
}
