import 'package:flutter/material.dart';

/// Layout metrics shared by category grid tiles so [GridView.childAspectRatio]
/// matches the real column height (image + gap + labels).
///
/// Used by [AnimatedCategoryCard] (tile), [CategoryTile], and category shimmers.
class CategoryGridLayout {
  CategoryGridLayout._();

  static const double tileImageGap = 6;
  static const double homeImageGap = 8;

  static const double nameFontSize = 11.5;
  static const double nameLineHeight = 1.15;
  static const int nameMaxLines = 2;

  static const double countFontSize = 9.5;
  static const double countLineHeight = 1.25;
  static const double countTopGap = 2;

  /// Rounding / font-metric slack so tiles never clip on dense grids.
  static const double textSafetyPadding = 4;

  static double _scaled(BuildContext context, double size) {
    return MediaQuery.textScalerOf(context).scale(size);
  }

  /// Vertical space below the square image (name + optional item count).
  static double textBlockHeight(
    BuildContext context, {
    bool includeItemCount = true,
  }) {
    final nameLine = _scaled(context, nameFontSize) * nameLineHeight;
    final nameBlock = nameLine * nameMaxLines;
    if (!includeItemCount) {
      return nameBlock + textSafetyPadding;
    }
    final countLine = _scaled(context, countFontSize) * countLineHeight;
    return nameBlock + countTopGap + countLine + textSafetyPadding;
  }

  /// Width ÷ height for [SliverGridDelegateWithFixedCrossAxisCount].
  static double childAspectRatio(
    BuildContext context,
    double cellWidth, {
    double imageToTextGap = tileImageGap,
    bool includeItemCount = true,
  }) {
    final tileHeight = cellWidth +
        imageToTextGap +
        textBlockHeight(context, includeItemCount: includeItemCount);
    return cellWidth / tileHeight;
  }
}
