import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// Wraps product / banner images so light artwork stays readable in dark mode.
///
/// Adds a subtle border (and optional card fill) when the app is in dark theme.
class ThemedNetworkImageFrame extends StatelessWidget {
  const ThemedNetworkImageFrame({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.forceBorder = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final bool forceBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = context.isDarkTheme;
    final radius = borderRadius ?? AppRadii.all(AppRadii.md);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? palette.card : null,
        borderRadius: radius,
        border: (isDark || forceBorder)
            ? Border.all(color: palette.imageBorder, width: 0.8)
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
