import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Inline “couldn’t load this section” card — neutral, Blinkit-style (no red crash).
class HomeSectionErrorCard extends StatelessWidget {
  const HomeSectionErrorCard({
    super.key,
    this.title,
    this.subtitle,
    required this.onRetry,
    this.minHeight = 120,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback onRetry;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? context.l10n.something_went_wrong;
    final resolvedSubtitle =
        subtitle ?? context.l10n.maintenance_offline;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (context, t, child) {
        return Opacity(opacity: t, child: child);
      },
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        width: double.infinity,
        margin: EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppSurface.of(context).subtle.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppSurface.of(context).border),
          boxShadow: AppShadow.dim,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_sync_rounded, size: 30, color: Colors.grey.shade600),
            SizedBox(height: 8),
            Text(
              resolvedTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppSurface.of(context).textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              resolvedSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppSurface.of(context).textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.retry),
              style: FilledButton.styleFrom(
                foregroundColor: AppColor.primary,
                backgroundColor: AppSurface.of(context).card,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
