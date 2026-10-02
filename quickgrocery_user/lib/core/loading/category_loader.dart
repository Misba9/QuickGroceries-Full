import 'package:flutter/foundation.dart';

/// One visual used by the category loading animation.
///
/// Built dynamically from live [CategoryModel]s (or local asset fallbacks).
@immutable
class CategoryLoaderItem {
  const CategoryLoaderItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.assetPath,
    this.emoji,
  });

  final String id;
  final String name;

  /// Network image from Firestore category.image.
  final String? imageUrl;

  /// Local grocery asset fallback.
  final String? assetPath;

  /// Last-resort icon glyph when no image/asset.
  final String? emoji;

  bool get hasNetworkImage =>
      imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get hasAsset => assetPath != null && assetPath!.isNotEmpty;

  bool get hasVisual => hasNetworkImage || hasAsset || (emoji?.isNotEmpty ?? false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryLoaderItem &&
          id == other.id &&
          name == other.name &&
          imageUrl == other.imageUrl &&
          assetPath == other.assetPath;

  @override
  int get hashCode => Object.hash(id, name, imageUrl, assetPath);
}
