import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/core/widgets/skeleton.dart';
import 'package:quickgrocery/core/widgets/staggered_fade_in.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/app_content/presentation/widgets/animated_app_heading.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';

/// Curated "Flash Sale" rail.
///
/// Composes a list from the trending + featured streams the homepage
/// already subscribes to (no extra Firestore reads), keeps anything
/// with a 25%+ discount and renders a high-energy countdown header.
///
/// The countdown is purely UX — it ticks down to the next 4-hour
/// boundary so the timer feels alive without requiring an admin schema
/// change. Once a `flashSaleEndsAt` field exists on documents, swap
/// [_endTime] for the document field.
class FlashSaleSection extends ConsumerStatefulWidget {
  const FlashSaleSection({
    super.key,
    this.minDiscountPercent = 25,
    this.cardMargin = const EdgeInsets.only(top: 12),
    this.heading,
    this.headingLoading = false,
  });

  final int minDiscountPercent;

  /// Admin-configured title; when null the parent should pass Firestore copy.
  final String? heading;
  final bool headingLoading;

  /// Outer margin around the gradient card (Categories sets [EdgeInsets.zero]
  /// when a section title sits above).
  final EdgeInsetsGeometry cardMargin;

  @override
  ConsumerState<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends ConsumerState<FlashSaleSection> {
  late DateTime _endTime;
  late Timer _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _endTime = _nextBoundary();
    _remaining = _endTime.difference(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      if (now.isAfter(_endTime)) {
        setState(() {
          _endTime = _nextBoundary();
          _remaining = _endTime.difference(now);
        });
      } else {
        setState(() => _remaining = _endTime.difference(now));
      }
    });
  }

  DateTime _nextBoundary() {
    final now = DateTime.now();
    final addedHours = 4 - (now.hour % 4);
    return DateTime(now.year, now.month, now.day, now.hour)
        .add(Duration(hours: addedHours));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(trendingProductsStreamProvider);
    final featured = ref.watch(featuredProductsStreamProvider);

    final loading = trending.isLoading || featured.isLoading;
    final List<ProductModel> pool = [
      ...trending.asData?.value ?? const [],
      ...featured.asData?.value ?? const [],
    ];

    final seen = <String>{};
    final discounted = pool
        .where((p) => p.discountPercent >= widget.minDiscountPercent)
        .where((p) => seen.add(p.id))
        .toList();

    final title = widget.heading ?? 'Flash deals';

    if (loading && discounted.isEmpty) {
      return _Card(
        margin: widget.cardMargin,
        end: _remaining,
        heading: title,
        headingLoading: widget.headingLoading,
        child: Builder(
          builder: (context) => SkeletonRail(
            count: 4,
            height: Responsive.horizontalProductRailHeight(context),
          ),
        ),
      );
    }
    if (discounted.isEmpty) return const SizedBox.shrink();

    discounted.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

    return _Card(
      margin: widget.cardMargin,
      end: _remaining,
      heading: title,
      headingLoading: widget.headingLoading,
      child: Builder(
        builder: (context) {
          final h = Responsive.horizontalProductRailHeight(context);
          return HorizontalProductRail(
            height: h,
            itemCount: discounted.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => StaggeredFadeIn(
              index: i,
              child: HomeProductCard(product: discounted[i]),
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.margin,
    required this.end,
    required this.heading,
    required this.child,
    this.headingLoading = false,
  });
  final EdgeInsetsGeometry margin;
  final Duration end;
  final String heading;
  final bool headingLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: AppGradients.flashSale,
        borderRadius: AppRadii.all(AppRadii.lg),
        boxShadow: AppShadow.card,
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: AnimatedAppHeading(
                        text: heading.toUpperCase(),
                        isLoading: headingLoading,
                        compact: true,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _Countdown(remaining: end),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Massive savings, just for now',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.all(AppRadii.md),
            ),
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Ends in $h:$m:$s',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
