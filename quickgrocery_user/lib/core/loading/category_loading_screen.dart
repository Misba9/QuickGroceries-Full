import 'package:flutter/material.dart';

import 'package:quickgrocery/core/loading/widgets/home_section_shimmer.dart';

/// Full-screen wait after startup — layout shimmer, never the category loop.
class CategoryLoadingScreen extends StatelessWidget {
  const CategoryLoadingScreen({
    super.key,
    this.background,
  });

  final Color? background;

  @override
  Widget build(BuildContext context) {
    if (background == null) return const HomePageShimmer();
    return ColoredBox(
      color: background!,
      child: const HomePageShimmer(),
    );
  }
}
