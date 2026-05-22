import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cached typography — avoids [GoogleFonts] lookups on every rebuild.
abstract final class AppTextStyles {
  static TextStyle get dashboardTitle => _cache['dashTitle'] ??= GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get dashboardSubtitle => _cache['dashSub'] ??= GoogleFonts.poppins(
        fontSize: 13,
        color: const Color(0xFF616161),
        height: 1.35,
      );

  static TextStyle get dashboardStatValue => _cache['dashStat'] ??= GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get sectionTitle => _cache['section'] ??= GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );

  /// Page headings (alias for section titles).
  static TextStyle get heading => sectionTitle;

  static final Map<String, TextStyle> _cache = {};
}
