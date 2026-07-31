import 'package:flutter/animation.dart';

/// Timing + sizing tokens for the premium grocery loading system.
abstract final class LoadingConstants {
  LoadingConstants._();

  /// @deprecated Logo splash removed — categories start immediately.
  static const logoFade = Duration(milliseconds: 720);
  static const logoScaleBegin = 0.92;
  static const logoScaleEnd = 1.0;

  /// Per-category: fade in 120 + hold 120 + fade/slide out 120 = 360ms.
  static const categoryFadeIn = Duration(milliseconds: 120);
  static const categoryHold = Duration(milliseconds: 120);
  static const categoryFadeOut = Duration(milliseconds: 120);
  static const categoryCycle = Duration(milliseconds: 360);
  static const categoryCycleMin = Duration(milliseconds: 360);
  static const categoryCycleMax = Duration(milliseconds: 450);

  /// After Home is interactive, wait before OS permission dialogs.
  static const permissionPromptSettle = Duration(milliseconds: 2800);

  /// Soft shimmer sweep for section placeholders.
  static const shimmerPeriod = Duration(milliseconds: 1200);

  /// Network image fade-in (reserved box → content). Keep short to avoid pop.
  static const imageFadeIn = Duration(milliseconds: 120);

  static const dotsPeriod = Duration(milliseconds: 420);
  static const textPulse = Duration(milliseconds: 1600);
  static const itemPulse = Duration(milliseconds: 1800);

  /// @deprecated Prefer completing logo via AnimationController status.
  static const logoPhase = logoFade;

  static const curve = Curves.easeInOut;

  static const imageSizeFull = 168.0;
  static const imageSizeCompact = 80.0;
  static const imageSizeMicro = 22.0;

  /// Splash exit + home enter — continuous crossfade feel.
  static const exitFade = Duration(milliseconds: 250);
  static const homeEnterFade = Duration(milliseconds: 250);

  static const logoAsset = 'assets/icons/logo.png';
}
