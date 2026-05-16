import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/constants/app_color.dart';

/// Section / header title with shimmer while loading and a soft cross-fade
/// when admin updates copy in Firestore.
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
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: fontSize * 1.2,
          width: compact ? 140 : 180,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Text(
        text,
        key: ValueKey<String>(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 12,
          width: 96,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Text(
        text,
        key: ValueKey<String>(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
