import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Branded gradient hero when Firestore has no banners — matches
/// [HomeBannerSlider] layout (16:7, peek slides, worm indicator).
class FallbackBannerSlider extends StatefulWidget {
  const FallbackBannerSlider({super.key});

  @override
  State<FallbackBannerSlider> createState() => _FallbackBannerSliderState();
}

class _FallbackBannerSliderState extends State<FallbackBannerSlider> {
  static const double _aspectRatio = 16 / 7;
  static const double _viewportFraction = 0.926;
  static const double _slideGap = 12;

  static final List<_FallbackSlide> _slides = [
    _FallbackSlide(
      title: 'Free delivery',
      subtitle: 'on your first order',
      icon: Icons.local_shipping_rounded,
      gradient: AppGradients.brand(),
    ),
    const _FallbackSlide(
      title: '10-minute delivery',
      subtitle: 'fresh groceries, lightning fast',
      icon: Icons.bolt_rounded,
      gradient: AppGradients.delivery,
    ),
    const _FallbackSlide(
      title: 'Up to 50% OFF',
      subtitle: 'on daily essentials',
      icon: Icons.local_offer_rounded,
      gradient: AppGradients.flashSale,
    ),
  ];

  int _index = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final slideW = viewportW * _viewportFraction;
        final carouselH = slideW / _aspectRatio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: carouselH,
              child: CarouselSlider.builder(
                carouselController: _controller,
                itemCount: _slides.length,
                itemBuilder: (context, i, _) =>
                    _FallbackSlideCard(slide: _slides[i]),
                options: CarouselOptions(
                  height: carouselH,
                  viewportFraction: _viewportFraction,
                  padEnds: true,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.06,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: AppMotion.medium,
                  autoPlayCurve: AppMotion.emphasized,
                  pauseAutoPlayOnTouch: true,
                  pauseAutoPlayOnManualNavigate: true,
                  enableInfiniteScroll: true,
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (i, _) => setState(() => _index = i),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: AppMotion.medium,
                      curve: AppMotion.emphasized,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: AppMotion.short,
                      curve: AppMotion.emphasized,
                      height: 6,
                      width: active ? 22 : 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColor.primary
                            : AppSurface.of(context).border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _FallbackSlide {
  const _FallbackSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
}

class _FallbackSlideCard extends StatelessWidget {
  const _FallbackSlideCard({required this.slide});
  final _FallbackSlide slide;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.banner);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _FallbackBannerSliderState._slideGap / 2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: slide.gradient,
          boxShadow: AppShadow.card,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AspectRatio(
            aspectRatio: _FallbackBannerSliderState._aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: -20,
                  child: Icon(
                    slide.icon,
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'QUICK GROCERY',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        slide.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slide.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
