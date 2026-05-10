import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

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
  });

  final CategoryModel category;
  final AnimatedCategoryCardVariant variant;
  final String heroPrefix;

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
          AnimatedCategoryCardVariant.tile => _Tile(category: widget.category, heroPrefix: widget.heroPrefix),
          AnimatedCategoryCardVariant.trendingHero =>
            _TrendingHero(category: widget.category, heroPrefix: widget.heroPrefix),
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.category, required this.heroPrefix});
  final CategoryModel category;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColor.primary.withValues(alpha: 0.10),
                        Colors.white,
                      ],
                    ),
                    borderRadius: AppRadii.all(AppRadii.md),
                    border: Border.all(color: AppSurface.border),
                    boxShadow: AppShadow.dim,
                  ),
                  padding: const EdgeInsets.all(8),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: Text(
            category.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppSurface.textPrimary,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingHero extends StatelessWidget {
  const _TrendingHero({required this.category, required this.heroPrefix});
  final CategoryModel category;
  final String heroPrefix;

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
    return SizedBox(
      width: 150,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.all(AppRadii.md),
          gradient: _accent(),
          boxShadow: AppShadow.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -22,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.all(AppRadii.sm),
                ),
                padding: const EdgeInsets.all(6),
                child: Hero(
                  tag: '$heroPrefix${category.id}-${category.name}',
                  child: CachedImage(
                    url: category.image,
                    fit: BoxFit.contain,
                    borderRadius: AppRadii.all(AppRadii.xs),
                    memCacheWidth: 180,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                      borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Shop now ›',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
