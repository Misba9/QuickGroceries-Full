import 'package:flutter/material.dart';

import '../design/app_tokens.dart';

/// Frosted, soft-shadow card used for premium sections (recommendations,
/// flash sale, recently ordered). Provides consistent inner padding and
/// optional background gradient.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius,
    this.gradient,
    this.color,
    this.border,
    this.elevation = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final Gradient? gradient;
  final Color? color;
  final BoxBorder? border;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: borderRadius ?? AppRadii.all(AppRadii.lg),
        border: border ?? Border.all(color: AppSurface.border),
        boxShadow: elevation ? AppShadow.card : null,
      ),
      child: child,
    );
  }
}
