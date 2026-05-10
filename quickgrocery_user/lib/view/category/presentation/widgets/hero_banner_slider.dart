import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/fallback_banner_slider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_helpers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_banner_slider.dart';

/// Riverpod-backed hero banner slot for the Categories discovery page.
///
/// Re-uses [HomeBannerSlider] (image + video, autoplay, worm indicator)
/// when Firestore returns banners, falling back to the branded
/// [FallbackBannerSlider] when none exist or while data is loading.
class HeroBannerSlider extends ConsumerWidget {
  const HeroBannerSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBanners = ref.watch(bannersStreamProvider);

    return asyncBanners.when(
      data: (banners) {
        if (banners.isEmpty) return const FallbackBannerSlider();
        final carousel = imageCarouselBanners(banners);
        if (carousel.isEmpty) return const FallbackBannerSlider();
        return HomeBannerSlider(banners: carousel);
      },
      loading: () => const _HeroSkeleton(),
      error: (_, __) => const FallbackBannerSlider(),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    final height = (width * 7 / 16).clamp(168.0, 280.0);
    return SizedBox(
      width: width,
      height: height,
      child: const Skeleton(radius: 18),
    );
  }
}
