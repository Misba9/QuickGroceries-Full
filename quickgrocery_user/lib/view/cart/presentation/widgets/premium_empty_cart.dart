import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// **PremiumEmptyCart** — illustrative empty state with a clear CTA to
/// browse categories. Used by [CartScreen] when [CartState.isEmpty] is
/// true and we're past the hydration step.
class PremiumEmptyCart extends StatelessWidget {
  const PremiumEmptyCart({super.key, this.onBrowse});

  /// Called when the user taps the "Start shopping" CTA.
  /// If null, no button is rendered (e.g. when used inside a tab where
  /// the home screen is just one swipe away).
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    final h = math.min(
      220.0,
      MediaQuery.sizeOf(context).height * 0.30,
    ).clamp(140.0, 220.0);
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: h,
              child: LottieBuilder.asset(
                'assets/lottie/no.json',
                repeat: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'cart_is_empty'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppSurface.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Looks like you haven\'t added anything yet.\n'
              'Start exploring fresh groceries!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppSurface.textMuted,
                height: 1.4,
              ),
            ),
            if (onBrowse != null) ...[
              const SizedBox(height: 18),
              _BrowseButton(onTap: onBrowse!),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrowseButton extends StatelessWidget {
  const _BrowseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.brand(),
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadow.primaryGlow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Start shopping',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
