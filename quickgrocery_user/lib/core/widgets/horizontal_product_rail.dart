import 'package:flutter/material.dart';

/// Shared scroll physics for horizontal product rails (nested in vertical
/// [CustomScrollView] / [ListView]).
const ScrollPhysics kHorizontalProductRailPhysics = BouncingScrollPhysics();

/// Standard horizontal list for product cards.
class HorizontalProductRail extends StatelessWidget {
  const HorizontalProductRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.separatorBuilder,
    required this.itemBuilder,
    this.itemExtent,
  });

  final double height;
  final int itemCount;
  final Widget Function(BuildContext, int) separatorBuilder;
  final Widget Function(BuildContext, int) itemBuilder;

  /// Fixed card width. When set, uses [ListView.builder] with a stable
  /// [itemExtent] (card + 10px gap) for cheaper horizontal layout.
  final double? itemExtent;

  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: itemExtent == null
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: kHorizontalProductRailPhysics,
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              separatorBuilder: separatorBuilder,
              itemBuilder: itemBuilder,
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: kHorizontalProductRailPhysics,
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              itemExtent: itemExtent! + _gap,
              itemBuilder: (context, i) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: itemExtent,
                    child: itemBuilder(context, i),
                  ),
                );
              },
            ),
    );
  }
}
