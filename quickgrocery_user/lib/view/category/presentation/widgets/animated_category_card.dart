import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/category/presentation/utils/category_grid_layout.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Premium animated category card used by the Categories discovery
/// screen. Two presentations:
///
///   * **Tile** (default) — square thumbnail + label, used in 4 / 6 / 8
///     column responsive grids.
///   * **Trending hero** — wider card with gradient background + larger
///     image + "Shop now" affordance, used in the trending rail.
///
/// Both presentations:
///   * Press-scale animation (haptic on tap).
///   * Hero handoff into [CategoryScreen] (matches the product card hero).
///   * Brand gradient ring on the image so categories pop on the soft
///     background even when the catalog uses muted product photos.
class AnimatedCategoryCard extends StatefulWidget {
  const AnimatedCategoryCard({
    super.key,
    required this.category,
    this.variant = AnimatedCategoryCardVariant.tile,
    this.heroPrefix = 'cat-',
    this.productCount,
    this.topDiscountPercent,
  });

  final CategoryModel category;
  final AnimatedCategoryCardVariant variant;
  final String heroPrefix;

  /// From live product inventory (optional).
  final int? productCount;

  /// Highest discount percent in category (shows badge when > 0).
  final int? topDiscountPercent;

  @override
  State<AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

enum AnimatedCategoryCardVariant { tile, trendingHero }

class _AnimatedCategoryCardState extends State<AnimatedCategoryCard> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  void _open() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(category: widget.category.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.96 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: _open,
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.short,
        curve: AppMotion.spring,
        child: switch (widget.variant) {
          AnimatedCategoryCardVariant.tile => _Tile(
              category: widget.category,
              heroPrefix: widget.heroPrefix,
              productCount: widget.productCount,
              topDiscountPercent: widget.topDiscountPercent,
            ),
          AnimatedCategoryCardVariant.trendingHero =>
            _TrendingHero(
              category: widget.category,
              heroPrefix: widget.heroPrefix,
              productCount: widget.productCount,
              topDiscountPercent: widget.topDiscountPercent,
            ),
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.category,
    required this.heroPrefix,
    this.productCount,
    this.topDiscountPercent,
  });
  final CategoryModel category;
  final String heroPrefix;
  final int? productCount;
  final int? topDiscountPercent;

  @override
  Widget build(BuildContext context) {
    final disc = topDiscountPercent ?? 0;
    final count = productCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColor.primary.withValues(alpha: 0.16),
                          Colors.white,
                          AppSurface.subtle.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: AppRadii.all(AppRadii.lg),
                      border: Border.all(
                        color: AppSurface.border.withValues(alpha: 0.8),
                      ),
                      boxShadow: AppShadow.card,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Hero(
                      tag: '$heroPrefix${category.id}-${category.name}',
                      child: CachedImage(
                        url: category.image,
                        fit: BoxFit.contain,
                        borderRadius: AppRadii.all(AppRadii.sm),
                        memCacheWidth: 240,
                      ),
                    ),
                  ),
                  if (disc > 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppSurface.danger,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: AppShadow.dim,
                        ),
                        child: Text(
                          '$disc%',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: CategoryGridLayout.tileImageGap),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                category.name,
                maxLines: CategoryGridLayout.nameMaxLines,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: CategoryGridLayout.nameFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppSurface.textPrimary,
                  height: CategoryGridLayout.nameLineHeight,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(height: CategoryGridLayout.countTopGap),
                Text(
                  context.l10n.items_in_category(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: CategoryGridLayout.countFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppSurface.textMuted,
                    height: CategoryGridLayout.countLineHeight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendingHero extends StatelessWidget {
  const _TrendingHero({
    required this.category,
    required this.heroPrefix,
    this.productCount,
    this.topDiscountPercent,
  });
  final CategoryModel category;
  final String heroPrefix;
  final int? productCount;
  final int? topDiscountPercent;

  /// Deterministic accent gradient picked from the category name so each
  /// hero gets a consistent (but varied) palette without admin config.
  LinearGradient _accent() {
    final palettes = const [
      [Color(0xFF7B61FF), Color(0xFF4F8DFF)],
      [Color(0xFFFF7A1A), Color(0xFFFF3D5A)],
      [Color(0xFF1FB454), Color(0xFF11A04C)],
      [Color(0xFFFFB200), Color(0xFFFF7A1A)],
      [Color(0xFF4ED4F2), Color(0xFF2680EB)],
    ];
    final idx = category.name.codeUnits.fold<int>(0, (a, b) => a + b) %
        palettes.length;
    final p = palettes[math.max(0, idx)];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [p[0], p[1]],
    );
  }

  @override
  Widget build(BuildContext context) {
    final disc = topDiscountPercent ?? 0;
    final count = productCount;
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
        height: 162,
        child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.all(20),
          boxShadow: AppShadow.raised,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.all(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: _accent(),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -28,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                if (disc > 0)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.percent_rounded,
                              color: Colors.limeAccent.shade200, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '$disc% ${context.l10n.off}',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 14,
                  bottom: 46,
                  child: Material(
                    color: Colors.white,
                    elevation: 6,
                    shadowColor: Colors.black26,
                    borderRadius: AppRadii.all(AppRadii.md),
                    child: SizedBox(
                      width: 78,
                      height: 78,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Hero(
                          tag: '$heroPrefix${category.id}-${category.name}',
                          child: CachedImage(
                            url: category.image,
                            fit: BoxFit.contain,
                            borderRadius: AppRadii.all(AppRadii.sm),
                            memCacheWidth: 200,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 96, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TRENDING',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.12,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              offset: const Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (count != null && count > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.items_in_category(count),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop now ›',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColor.primary,
                              ),
                            ),
                          ],
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
    ),
    );
  }
}
