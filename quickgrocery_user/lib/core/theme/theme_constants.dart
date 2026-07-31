import 'package:flutter/material.dart';

/// Shared timing / motion constants for theme transitions.
class ThemeConstants {
  ThemeConstants._();

  /// Duration for [AnimatedTheme] / MaterialApp theme animation.
  static const Duration animationDuration = Duration(milliseconds: 300);

  static const Curve animationCurve = Curves.easeInOut;

  /// SharedPreferences key for appearance mode.
  static const String preferenceKey = 'theme_mode';

  static const String storageLight = 'light';
  static const String storageDark = 'dark';
  static const String storageSystem = 'system';
}
