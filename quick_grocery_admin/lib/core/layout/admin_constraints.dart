import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Builds normalized [BoxConstraints] (minWidth never exceeds maxWidth).
BoxConstraints adminNormalizedConstraints({
  required double viewportWidth,
  double? viewportHeight,
  double? capMaxWidth,
  double minHeight = 0,
}) {
  final rawMaxW = viewportWidth.isFinite ? viewportWidth : 1200.0;
  final maxW = capMaxWidth != null ? math.min(rawMaxW, capMaxWidth) : rawMaxW;
  return BoxConstraints(
    minWidth: 0,
    maxWidth: math.max(0, maxW),
    minHeight: math.max(0, minHeight),
  );
}
