class ProductImageLimits {
  ProductImageLimits._();

  static const int minImages = 1;
  static const int maxImages = 8;
  static const int maxFileBytes = 5 * 1024 * 1024; // 5 MB
  static const int pickQuality = 82;
  static const int maxWidth = 1200;
  static const int maxHeight = 1200;

  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  static bool isAllowedExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return allowedExtensions.contains(ext);
  }
}
