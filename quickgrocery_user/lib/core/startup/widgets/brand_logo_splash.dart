import 'package:flutter/material.dart';

import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/startup/widgets/app_animated_splash.dart';

/// Ensures Step 1 (yellow + logo) lasts ~[LoadingConstants.logoFade] once
/// Flutter paints — seamless continuation of the native splash.
abstract final class LaunchLogoHold {
  LaunchLogoHold._();

  static final Stopwatch _sw = Stopwatch();

  /// Call on first Flutter logo paint (Firebase gate / splash).
  static void markStarted() {
    if (!_sw.isRunning) _sw.start();
  }

  static bool get isComplete =>
      _sw.isRunning && _sw.elapsed >= LoadingConstants.logoFade;

  /// Remaining hold time before categories may start. Zero if already done.
  static Duration get remaining {
    if (!_sw.isRunning) return LoadingConstants.logoFade;
    final left = LoadingConstants.logoFade - _sw.elapsed;
    return left.isNegative ? Duration.zero : left;
  }
}

/// Native-matching Step 1 visual — yellow field + large centered logo only.
class BrandLogoSplash extends StatelessWidget {
  const BrandLogoSplash({super.key});

  @override
  Widget build(BuildContext context) {
    LaunchLogoHold.markStarted();
    return ColoredBox(
      color: kLaunchYellow,
      child: Center(
        child: Image.asset(
          LoadingConstants.logoAsset,
          width: 180,
          height: 180,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 180,
            height: 180,
          ),
        ),
      ),
    );
  }
}
