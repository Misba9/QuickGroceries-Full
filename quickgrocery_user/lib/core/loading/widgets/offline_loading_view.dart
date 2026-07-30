import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/widgets/animated_category_loader.dart';

/// Friendly offline state instead of infinite loading.
class OfflineLoadingView extends StatelessWidget {
  const OfflineLoadingView({
    super.key,
    this.onRetry,
    this.title = 'You\'re offline',
    this.subtitle =
        'Check your connection and try again. We\'ll reload the freshest groceries.',
  });

  final VoidCallback? onRetry;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedCategoryLoader(
              compact: true,
              showCard: false,
              rotateEvery: Duration(milliseconds: 3200),
              semanticsLabel: 'Offline',
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: surface.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: surface.textSecondary,
                height: 1.45,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
