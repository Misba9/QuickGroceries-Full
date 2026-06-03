import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/category/presentation/utils/category_grid_layout.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer building blocks scoped to the homepage. Centralizes the shimmer
/// look so all sections animate in sync.
class HomeShimmer {
  const HomeShimmer._();

  static Widget _box({double? width, double? height, double radius = 8}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  static Widget categoriesGrid({int count = 8, int crossAxisCount = 4}) {
    const crossSpacing = 10.0;
    const mainSpacing = 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - crossSpacing * (crossAxisCount - 1)) /
                crossAxisCount;
        final ratio = CategoryGridLayout.childAspectRatio(
          context,
          tileWidth,
          imageToTextGap: CategoryGridLayout.homeImageGap,
          includeItemCount: false,
        );
        final labelHeight = CategoryGridLayout.textBlockHeight(
          context,
          includeItemCount: false,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
            childAspectRatio: ratio,
          ),
          itemCount: count,
          itemBuilder: (_, __) => Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _box(radius: 16),
                  ),
                ),
              ),
              const SizedBox(height: CategoryGridLayout.homeImageGap),
              SizedBox(
                height: labelHeight,
                child: Center(
                  child: _box(height: 10, width: 60, radius: 4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget categoriesRail({int count = 8}) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SizedBox(
          width: 96,
          child: Column(
            children: [
              Expanded(child: _box(radius: 18)),
              const SizedBox(height: 8),
              _box(height: 10, width: 52, radius: 4),
            ],
          ),
        ),
      ),
    );
  }

  static Widget videoRail({bool showHeader = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          _box(height: 18, width: 120, radius: 6),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => _box(height: 218, width: 300, radius: 24),
          ),
        ),
      ],
    );
  }

  static Widget banner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const viewportFraction = 0.926;
        final slideW = constraints.maxWidth * viewportFraction;
        final height = slideW * 7 / 16;
        return Column(
          children: [
            _box(height: height, radius: AppRadii.banner),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _box(
                    height: 6,
                    width: i == 0 ? 22 : 6,
                    radius: 3,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget horizontalProducts({double height = 248}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: kHorizontalProductRailPhysics,
        itemCount: 4,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1, child: _box(radius: 12))),
              const SizedBox(height: 8),
              _box(height: 10, width: 80),
              const SizedBox(height: 6),
              _box(height: 10, width: 120),
              const SizedBox(height: 8),
              Row(
                children: [
                  _box(height: 14, width: 60),
                  const Spacer(),
                  _box(height: 24, width: 50, radius: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder while the Firestore admin gate connects (landing tab shell).
  static Widget landingTabShell() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _box(height: 26, width: 140, radius: 10),
              const SizedBox(height: 18),
              Expanded(
                flex: 3,
                child: _box(radius: 18),
              ),
              const SizedBox(height: 14),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(child: _box(radius: 14)),
                    const SizedBox(width: 12),
                    Expanded(child: _box(radius: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget exploreGrid({int count = 6}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 8,
        childAspectRatio: 0.60,
      ),
      itemCount: count,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child: _box(radius: 12)),
          const SizedBox(height: 6),
          _box(height: 10, width: 80),
          const SizedBox(height: 6),
          _box(height: 10, width: 120),
          const SizedBox(height: 8),
          _box(height: 14, width: 60),
        ],
      ),
    );
  }
}
