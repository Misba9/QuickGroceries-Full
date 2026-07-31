import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Best-effort preload of fonts / image bytes used by loaders.
abstract final class LoadingAssets {
  LoadingAssets._();

  static bool _didWarm = false;

  /// Call after first frame (splash) — never blocks UI.
  static Future<void> warmUp() async {
    if (_didWarm) return;
    _didWarm = true;
    try {
      // Resolve Poppins off the critical first-frame path; [AppTheme] is
      // already memoized. Pending fetch completes in the background.
      final text = GoogleFonts.poppins();
      await GoogleFonts.pendingFonts([text]);
      await Future.wait([
        rootBundle.load('assets/icons/logo.png'),
        rootBundle.load('assets/images/dairy.png'),
        rootBundle.load('assets/images/vegitable.png'),
        rootBundle.load('assets/images/mango.png'),
      ]);
    } catch (_) {
      // Non-fatal — loaders still work without pre-cache.
    }
  }
}
