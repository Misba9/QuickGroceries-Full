import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Inline error placeholder used for failing sections (banner, trending,
/// featured rails). Compact enough to live inside a horizontal rail.
class HomeErrorView extends StatelessWidget {
  const HomeErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.height = 140,
  });

  final String message;
  final VoidCallback? onRetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final isDark = context.isDarkTheme;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface.danger.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: surface.danger.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: surface.danger, size: 28),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? surface.textPrimary : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Retry',
                style: TextStyle(color: AppColor.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty placeholder used when a section has zero results.
class HomeEmptyView extends StatelessWidget {
  const HomeEmptyView({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.height = 120,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface.subtle,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: surface.iconInactive, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: surface.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: surface.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
