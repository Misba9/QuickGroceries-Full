import 'package:flutter/material.dart';

/// Provides the **content area** max width (viewport minus sidebar).
/// Set once in [HomeScreen] so child screens stop using full-screen [MediaQuery].
class AdminContentScope extends InheritedWidget {
  const AdminContentScope({
    super.key,
    required this.maxWidth,
    required super.child,
  });

  final double maxWidth;

  static AdminContentScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminContentScope>();
  }

  static double contentWidth(BuildContext context) {
    final scope = maybeOf(context);
    if (scope != null && scope.maxWidth.isFinite && scope.maxWidth > 0) {
      return scope.maxWidth;
    }
    return MediaQuery.sizeOf(context).width;
  }

  /// Fraction of content width, clamped — use instead of `MediaQuery.width * .4`.
  static double fraction(BuildContext context, double frac) {
    final w = contentWidth(context);
    return (w * frac).clamp(0.0, w);
  }

  @override
  bool updateShouldNotify(AdminContentScope oldWidget) =>
      oldWidget.maxWidth != maxWidth;
}
