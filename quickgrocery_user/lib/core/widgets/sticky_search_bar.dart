import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/app_search_bar.dart';

/// Reusable pinned search bar for [CustomScrollView] screens.
///
/// Starts in its natural position (optionally below [topContent] that
/// scrolls away). Once the user scrolls, the search bar sticks beneath
/// any outer pinned headers and gains elevation.
///
/// Use [StickySearchBar.asSliver] inside a sliver list, or [StickySearchBar]
/// directly for fixed-header layouts (e.g. category product screen).
class StickySearchBar extends StatelessWidget {
  const StickySearchBar({
    super.key,
    required this.searchBar,
    this.elevated = false,
  });

  /// The search field — typically an [AppSearchBar].
  final Widget searchBar;

  /// When true, renders the stuck-state shadow (for fixed headers).
  final bool elevated;

  /// Height of [AppSearchBar] — keep in sync with [AppSearchBar] layout.
  static const double barHeight = 52;

  /// Builds a pinned [SliverPersistentHeader] wrapping [searchBar].
  static Widget asSliver({
    Key? key,
    required double gutter,
    required Widget searchBar,
    Widget? topContent,
    double topContentHeight = 0,
    double topPadding = 6,
    double bottomPadding = 14,
    double gap = 8,
  }) {
    return SliverPersistentHeader(
      key: key,
      pinned: true,
      delegate: StickySearchBarDelegate(
        gutter: gutter,
        searchBar: searchBar,
        topContent: topContent,
        topContentHeight: topContentHeight,
        topPadding: topPadding,
        bottomPadding: bottomPadding,
        gap: gap,
      ),
    );
  }

  /// Convenience factory for the common tappable [AppSearchBar] pattern.
  static Widget tappableSliver({
    Key? key,
    required double gutter,
    required List<String> hints,
    required VoidCallback onTap,
    Widget? topContent,
    double topContentHeight = 0,
    double topPadding = 6,
    double bottomPadding = 14,
    double gap = 8,
  }) {
    return asSliver(
      key: key,
      gutter: gutter,
      topContent: topContent,
      topContentHeight: topContentHeight,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      gap: gap,
      searchBar: AppSearchBar(hints: hints, onTap: onTap),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppSurface.of(context).background,
      elevation: elevated ? 3 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppSurface.of(context).background,
          border: elevated
              ? Border(
                  bottom: BorderSide(
                    color: AppSurface.of(context).border.withValues(alpha: 0.85),
                    width: 0.6,
                  ),
                )
              : null,
        ),
        child: searchBar,
      ),
    );
  }
}

/// [SliverPersistentHeaderDelegate] that collapses optional [topContent]
/// while keeping [searchBar] pinned with a smooth elevation transition.
class StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  StickySearchBarDelegate({
    required this.gutter,
    required this.searchBar,
    this.topContent,
    this.topContentHeight = 0,
    this.topPadding = 6,
    this.bottomPadding = 14,
    this.gap = 8,
  });

  final double gutter;
  final Widget searchBar;
  final Widget? topContent;
  final double topContentHeight;
  final double topPadding;
  final double bottomPadding;
  final double gap;

  bool get _hasCollapsingHeader =>
      topContent != null && topContentHeight > 0;

  @override
  double get maxExtent {
    if (!_hasCollapsingHeader) {
      return topPadding + StickySearchBar.barHeight + bottomPadding;
    }
    return topPadding +
        topContentHeight +
        gap +
        StickySearchBar.barHeight +
        bottomPadding;
  }

  @override
  double get minExtent =>
      topPadding + StickySearchBar.barHeight + bottomPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final t = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 0.0;
    final isStuck = overlapsContent || shrinkOffset > 0;
    final elevation = isStuck ? (3.0 * (0.35 + 0.65 * t)) : 0.0;
    final headerOpacity =
        _hasCollapsingHeader ? (1 - t * 1.85).clamp(0.0, 1.0) : 0.0;

    final searchTop = _hasCollapsingHeader
        ? topPadding + topContentHeight + gap - (t * (topContentHeight + gap))
        : topPadding;

    return Material(
      color: AppSurface.of(context).background,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          color: AppSurface.of(context).background,
          border: isStuck
              ? Border(
                  bottom: BorderSide(
                    color: AppSurface.of(context).border.withValues(alpha: 0.35 + 0.5 * t),
                    width: 0.6,
                  ),
                )
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_hasCollapsingHeader)
              Positioned(
                left: gutter,
                right: gutter,
                top: topPadding,
                child: Opacity(
                  opacity: headerOpacity,
                  child: topContent,
                ),
              ),
            Positioned(
              left: gutter,
              right: gutter,
              top: searchTop,
              child: searchBar,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickySearchBarDelegate oldDelegate) {
    return oldDelegate.gutter != gutter ||
        oldDelegate.topContentHeight != topContentHeight ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.bottomPadding != bottomPadding ||
        oldDelegate.gap != gap ||
        oldDelegate.topContent != topContent ||
        oldDelegate.searchBar != searchBar;
  }
}
