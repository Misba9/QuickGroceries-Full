import 'package:flutter/material.dart';

import 'package:quickgrocery/core/loading/category_loading_widget.dart';
import 'package:quickgrocery/core/loading/loading_theme.dart';
import 'package:quickgrocery/core/loading/widgets/home_section_shimmer.dart';

extension LoadingBuildContext on BuildContext {
  LoadingTheme get loadingTheme => LoadingTheme.of(this);

  /// Startup-only category animation helper (prefer [AppAnimatedSplash]).
  Widget categoryLoading({
    bool compact = true,
    bool fullScreen = false,
  }) {
    return CategoryLoadingWidget(
      compact: compact,
      fullScreen: fullScreen,
    );
  }

  Widget get loadingCenter => const Center(
        child: SizedBox(
          width: 120,
          height: 80,
          child: SectionBlockShimmer(height: 72),
        ),
      );
}

/// Loading helpers.
///
/// - Startup splash uses [CategoryLoadingWidget] directly.
/// - Home / page sections use layout-matched shimmers (never category loop).
/// - Buttons use [micro] / [spinner].
abstract final class AppLoading {
  AppLoading._();

  /// In-flow wait — layout block shimmer (not category animation).
  static const Widget center = Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: SectionBlockShimmer(height: 96),
  );

  /// Full-page wait — home-shaped shimmer (never category animation).
  static const Widget fullScreen = HomePageShimmer();

  /// Generic section wait.
  static const Widget section = ProductRailShimmer();

  /// Banner carousel placeholder.
  static const Widget banner = BannerSectionShimmer();

  /// Category rail placeholder.
  static const Widget categoryRail = CategoryRailShimmer();

  /// Horizontal product rail placeholder.
  static const Widget productRail = ProductRailShimmer();

  /// Explore grid placeholder.
  static const Widget exploreGrid = ExploreGridShimmer();

  /// Tiny button / inline spinner — never the category animation.
  static const Widget micro = SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2.2,
      color: Color(0xFF1A1A1A),
    ),
  );

  /// Button spinner with an explicit color (e.g. white on primary CTAs).
  static Widget spinner({
    double size = 18,
    Color color = const Color(0xFF1A1A1A),
    double strokeWidth = 2.2,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
      ),
    );
  }
}
