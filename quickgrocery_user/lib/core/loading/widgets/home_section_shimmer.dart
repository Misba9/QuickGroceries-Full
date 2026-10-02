import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_constants.dart';

/// Lightweight shimmer without an external package.
///
/// Uses [AppPalette.shimmerBase] / [shimmerHighlight] so light/dark stay correct.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: LoadingConstants.shimmerPeriod,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(palette.shimmerBase, BlendMode.srcIn),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.4 + 2.8 * t, -0.15),
              end: Alignment(-0.1 + 2.8 * t, 0.15),
              colors: [
                palette.shimmerBase,
                palette.shimmerHighlight,
                palette.shimmerHighlight,
                palette.shimmerBase,
              ],
              stops: const [0.2, 0.42, 0.58, 0.8],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    // Opaque fill for ShaderMask; tinted by [AppShimmer] sweep.
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Banner carousel placeholder — matches 16:7 home banner aspect.
class BannerSectionShimmer extends StatelessWidget {
  const BannerSectionShimmer({super.key});

  static const _aspect = 16 / 7;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final slideW = w * 0.926;
          final h = slideW / _aspect;
          return Column(
            children: [
              SizedBox(
                height: h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      width: slideW,
                      height: h,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: ShimmerBox(borderRadius: 24),
                      ),
                    ),
                    SizedBox(
                      width: slideW * 0.35,
                      height: h,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: ShimmerBox(borderRadius: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(width: 18, height: 6, borderRadius: 3),
                  SizedBox(width: 6),
                  ShimmerBox(width: 6, height: 6, borderRadius: 3),
                  SizedBox(width: 6),
                  ShimmerBox(width: 6, height: 6, borderRadius: 3),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontal category chip rail placeholder.
class CategoryRailShimmer extends StatelessWidget {
  const CategoryRailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const SizedBox(
            width: 96,
            child: Column(
              children: [
                ShimmerBox(width: 72, height: 72, borderRadius: 18),
                SizedBox(height: 10),
                ShimmerBox(width: 64, height: 10, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 48, height: 8, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal product rail placeholder.
class ProductRailShimmer extends StatelessWidget {
  const ProductRailShimmer({
    super.key,
    this.height = 220,
    this.cardWidth = 132,
  });

  final double height;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => SizedBox(
            width: cardWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: cardWidth,
                  height: cardWidth * 0.92,
                  borderRadius: 14,
                ),
                const SizedBox(height: 8),
                ShimmerBox(width: cardWidth * 0.9, height: 10, borderRadius: 4),
                const SizedBox(height: 6),
                ShimmerBox(width: cardWidth * 0.55, height: 10, borderRadius: 4),
                const SizedBox(height: 10),
                ShimmerBox(width: cardWidth * 0.4, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Explore / grid product placeholder.
class ExploreGridShimmer extends StatelessWidget {
  const ExploreGridShimmer({super.key, this.columns = 2});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: columns * 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ShimmerBox(borderRadius: 14)),
            SizedBox(height: 8),
            ShimmerBox(width: double.infinity, height: 10, borderRadius: 4),
            SizedBox(height: 6),
            ShimmerBox(width: 72, height: 10, borderRadius: 4),
            SizedBox(height: 8),
            ShimmerBox(width: 56, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Compact block used for generic in-flow section waits.
class SectionBlockShimmer extends StatelessWidget {
  const SectionBlockShimmer({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ShimmerBox(
          width: double.infinity,
          height: height,
          borderRadius: AppRadii.lg,
        ),
      ),
    );
  }
}

/// Full-page home-shaped skeleton (serviceability / rare full waits).
/// Never uses the startup category animation.
class HomePageShimmer extends StatelessWidget {
  const HomePageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return ColoredBox(
      color: surface.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            ShimmerBox(width: 160, height: 14, borderRadius: 4),
            SizedBox(height: 10),
            ShimmerBox(width: double.infinity, height: 44, borderRadius: 14),
            SizedBox(height: 16),
            BannerSectionShimmer(),
            SizedBox(height: 20),
            ShimmerBox(width: 140, height: 14, borderRadius: 4),
            SizedBox(height: 12),
            CategoryRailShimmer(),
            SizedBox(height: 20),
            ShimmerBox(width: 120, height: 14, borderRadius: 4),
            SizedBox(height: 12),
            ProductRailShimmer(),
            SizedBox(height: 20),
            ShimmerBox(width: 130, height: 14, borderRadius: 4),
            SizedBox(height: 12),
            ProductRailShimmer(),
          ],
        ),
      ),
    );
  }
}
