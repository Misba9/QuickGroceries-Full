import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/constants/app_color.dart';

/// Section / header title with empty placeholder while loading and a soft
/// cross-fade when admin updates copy in Firestore.
class AnimatedAppHeading extends StatelessWidget {
  const AnimatedAppHeading({
    super.key,
    required this.text,
    this.isLoading = false,
    this.style,
    this.compact = false,
  });

  final String text;
  final bool isLoading;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final fontSize = responsive.isDesktop
        ? 18.0
        : responsive.isTablet
            ? 17.0
            : compact
                ? 15.0
                : 16.0;

    final resolved = style ??
        GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          color: Colors.black87,
          height: 1.2,
          letterSpacing: -0.25,
        );

    if (isLoading) {
      // Prefer showing the known title; otherwise reserve space without shimmer.
      if (text.trim().isNotEmpty) {
        return Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: resolved,
        );
      }
      return SizedBox(height: fontSize * 1.2);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Text(
        text,
        key: ValueKey<String>(text),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        style: resolved,
      ),
    );
  }
}

/// Muted greeting line above the delivery strip / category header.
class AnimatedAppGreeting extends StatelessWidget {
  const AnimatedAppGreeting({
    super.key,
    required this.text,
    this.isLoading = false,
    this.style,
  });

  final String text;
  final bool isLoading;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (text.trim().isNotEmpty) {
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: style ??
              GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColor.primary.withValues(alpha: 0.85),
                height: 1.1,
              ),
        );
      }
      return const SizedBox(height: 12);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Text(
        text,
        key: ValueKey<String>(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        style: style ??
            GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColor.primary.withValues(alpha: 0.85),
              height: 1.1,
            ),
      ),
    );
  }
}
