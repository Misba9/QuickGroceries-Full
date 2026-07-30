import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Best-effort preload of fonts / Lottie bytes used by loaders.
abstract final class LoadingAssets {
  LoadingAssets._();

  static bool _didWarm = false;

  /// Call after first frame (DeferredStartup / splash) — never blocks UI.
  static Future<void> warmUp() async {
    if (_didWarm) return;
    _didWarm = true;
    try {
      GoogleFonts.poppins();
      await Future.wait([
        rootBundle.load('assets/lottie/load.json'),
        rootBundle.load('assets/lottie/burger.json'),
        rootBundle.load('assets/images/logo.png'),
      ]);
    } catch (_) {
      // Non-fatal — loaders still work without pre-cache.
    }
  }
}
