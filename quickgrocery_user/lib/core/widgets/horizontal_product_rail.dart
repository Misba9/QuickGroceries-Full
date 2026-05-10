import 'package:flutter/material.dart';

/// Shared scroll physics for horizontal product rails (nested in vertical
/// [CustomScrollView] / [ListView]).
const ScrollPhysics kHorizontalProductRailPhysics = BouncingScrollPhysics();

/// Standard horizontal [ListView.separated] for product cards.
class HorizontalProductRail extends StatelessWidget {
  const HorizontalProductRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.separatorBuilder,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final Widget Function(BuildContext, int) separatorBuilder;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: kHorizontalProductRailPhysics,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: separatorBuilder,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
