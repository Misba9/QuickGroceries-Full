import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/app_content/presentation/widgets/animated_app_heading.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_section_slot.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';

/// Curated "Flash Sale" rail.
///
/// Prefer products flagged `is_flash_sale`. Countdown ticks live in a leaf
/// widget so the product rail does **not** rebuild every second.
class FlashSaleSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final flashSale = ref.watch(flashSaleProductsStreamProvider);
    final trending = ref.watch(trendingProductsStreamProvider);
    final featured = ref.watch(featuredProductsStreamProvider);

    final loading = (flashSale.isLoading && !flashSale.hasValue) ||
        (trending.isLoading && !trending.hasValue) ||
        (featured.isLoading && !featured.hasValue);

    final seen = <String>{};
    final flagged = flashSale.asData?.value ?? const <ProductModel>[];
    final pool = <ProductModel>[
      ...flagged,
      ...trending.asData?.value ?? const [],
      ...featured.asData?.value ?? const [],
    ];

    final discounted = pool
        .where((p) => seen.add(p.id))
        .where(
          (p) =>
              p.isFlashSaleLive ||
              p.discountPercent >= minDiscountPercent,
        )
        .toList();

    discounted.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

    final nearestEnd = discounted
        .map((p) => p.flashSaleEnd)
        .whereType<DateTime>()
        .where((d) => d.isAfter(DateTime.now()))
        .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);

    final title = heading ?? 'Flash deals';

    return HomeSectionSlot(
      loading: loading && discounted.isEmpty,
      hideWhenEmpty: true,
      isEmpty: discounted.isEmpty,
      minHeight: 280,
      shimmer: _Card(
        margin: cardMargin,
        endTime: nearestEnd,
        heading: title,
        headingLoading: headingLoading,
        child: AppLoading.productRail,
      ),
      child: _Card(
        margin: cardMargin,
        endTime: nearestEnd,
        heading: title,
        headingLoading: headingLoading,
        child: Builder(
          builder: (context) {
            final h = Responsive.horizontalProductRailHeight(context);
            return HorizontalProductRail(
              height: h,
              itemExtent: HomeProductCard.railExtent,
              itemCount: discounted.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final p = discounted[i];
                return HomeProductCard(
                  key: ValueKey('flash-${p.id}'),
                  product: p,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.margin,
    required this.endTime,
    required this.heading,
    required this.child,
    this.headingLoading = false,
  });
  final EdgeInsetsGeometry margin;
  final DateTime? endTime;
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
        boxShadow: AppShadow.cardOf(context),
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
                    Text(
                      'FLASH DEALS',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _FlashCountdown(endTime: endTime),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedAppHeading(
              text: heading,
              isLoading: headingLoading,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.2,
                letterSpacing: -0.25,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Massive savings, just for now',
            textAlign: TextAlign.start,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppSurface.of(context).card,
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

/// Only this chip rebuilds on the 1 Hz ticker — never the product rail.
class _FlashCountdown extends StatefulWidget {
  const _FlashCountdown({required this.endTime});

  final DateTime? endTime;

  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  late DateTime _endTime;
  late Timer _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _endTime = widget.endTime ?? _nextBoundary();
    _remaining = _endTime.difference(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      if (now.isAfter(_endTime)) {
        setState(() {
          _endTime = widget.endTime != null && widget.endTime!.isAfter(now)
              ? widget.endTime!
              : _nextBoundary();
          _remaining = _endTime.difference(now);
        });
      } else {
        setState(() => _remaining = _endTime.difference(now));
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FlashCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.endTime;
    if (next != null && next != _endTime && next.isAfter(DateTime.now())) {
      _endTime = next;
      _remaining = _endTime.difference(DateTime.now());
    }
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
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
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
