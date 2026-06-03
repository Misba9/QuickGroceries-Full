import 'package:flutter/material.dart';

/// Bottom sheet-style panel that scrolls when content exceeds [maxHeightFraction]
/// of the viewport (avoids RenderFlex overflow on small screens / landscape).
class ScrollableBottomPanel extends StatelessWidget {
  const ScrollableBottomPanel({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.6,
    this.decoration,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
  });

  final Widget child;
  final double maxHeightFraction;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFraction;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: decoration ??
              BoxDecoration(
                color: Colors.black,
                borderRadius: borderRadius,
              ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: SingleChildScrollView(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
