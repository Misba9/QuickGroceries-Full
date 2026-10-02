import 'package:flutter/animation.dart';

/// Visual timing + sizing for the premium startup / loading UI only.
///
/// Native logo → full-screen category beat → 250ms Home fade.
abstract final class LoadingConstants {
  LoadingConstants._();

  /// STEP 1 — native + Flutter yellow logo bridge (0–400 ms total).
  static const logoFade = Duration(milliseconds: 400);
  static const logoScaleBegin = 0.98;
  static const logoScaleEnd = 1.0;

  /// Unused by Flutter splash (categories start immediately); kept for assets.
  static const logoToCategoryFade = Duration(milliseconds: 280);

  /// STEP 2 — one category at a time (fade + scale 0.95→1 + slight rise).
  /// ~470ms total — stay readable 400–500ms (Blinkit / Zepto beat).
  static const categoryFadeIn = Duration(milliseconds: 100);
  static const categoryHold = Duration(milliseconds: 280);
  static const categoryFadeOut = Duration(milliseconds: 90);
  static const categoryCycle = Duration(milliseconds: 470);
  static const categoryCycleMin = Duration(milliseconds: 400);
  static const categoryCycleMax = Duration(milliseconds: 500);

  /// After Home is interactive, wait before OS permission dialogs.
  static const permissionPromptSettle = Duration(milliseconds: 2800);

  /// Soft shimmer sweep for Home section placeholders.
  static const shimmerPeriod = Duration(milliseconds: 1400);

  /// Network image fade-in on Home (reserved box → content).
  static const imageFadeIn = Duration(milliseconds: 180);

  static const dotsPeriod = Duration(milliseconds: 420);
  static const textPulse = Duration(milliseconds: 1600);
  static const itemPulse = Duration(milliseconds: 1800);

  static const logoPhase = logoFade;

  static const Curve curve = Curves.easeOutCubic;
  static const Curve exitCurve = Cubic(0.2, 0, 0, 1);
  static const Curve revealCurve = Cubic(0.2, 0, 0, 1);

  /// Full-screen category icon — 90–120px (Blinkit/Zepto scale).
  static const imageSizeFull = 112.0;
  static const imageSizeCompact = 80.0;
  static const imageSizeMicro = 22.0;

  /// STEP 3 — splash → Home (250ms soft fade).
  static const exitFade = Duration(milliseconds: 250);
  static const homeEnterFade = Duration(milliseconds: 250);

  /// Soft reveal when a Home section swaps shimmer → content.
  static const sectionReveal = Duration(milliseconds: 260);

  /// Soft arm when deferred Home sections mount.
  static const armReveal = Duration(milliseconds: 200);

  static const logoAsset = 'assets/icons/logo.png';
}
