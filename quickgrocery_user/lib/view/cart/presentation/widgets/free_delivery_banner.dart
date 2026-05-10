import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// **FreeDeliveryBanner** — gradient progress card that nudges the user
/// toward the free-delivery threshold (Zepto / Blinkit pattern).
///
/// * **Already free** → green delivery gradient + checkmark + "Free
///   delivery applied".
/// * **Almost there** → animated linear progress bar from 0 → 1 with the
///   exact ₹ amount remaining.
/// * **Surge active** → orange tint + bolt icon + surge reason.
///
/// All variants share a single 14-radius card with [AppShadow.dim] so
/// the cart's vertical rhythm stays consistent.
class FreeDeliveryBanner extends StatelessWidget {
  const FreeDeliveryBanner({
    super.key,
    required this.subtotal,
    required this.threshold,
    this.surgeActive = false,
    this.surgeMultiplier = 1.0,
    this.surgeReason,
  });

  final double subtotal;
  final double threshold;
  final bool surgeActive;
  final double surgeMultiplier;
  final String? surgeReason;

  @override
  Widget build(BuildContext context) {
    if (surgeActive && surgeMultiplier > 1) {
      return _SurgeVariant(
        multiplier: surgeMultiplier,
        reason: surgeReason,
      );
    }

    if (threshold <= 0 || subtotal >= threshold) {
      return const _FreeNowVariant();
    }

    final remaining = (threshold - subtotal).clamp(0.0, threshold);
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    return _AlmostThereVariant(
      remaining: remaining,
      progress: progress,
    );
  }
}

// ─── Variants ──────────────────────────────────────────────────────────────

class _FreeNowVariant extends StatelessWidget {
  const _FreeNowVariant();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: AppGradients.delivery,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadow.dim,
      ),
      child: Row(
        children: [
          _IconBubble(icon: Icons.local_shipping_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yay! Free delivery unlocked',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your order qualifies for free delivery',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 22),
        ],
      ),
    );
  }
}

class _AlmostThereVariant extends StatelessWidget {
  const _AlmostThereVariant({
    required this.remaining,
    required this.progress,
  });

  final double remaining;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.dim,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _IconBubble(
                icon: Icons.local_shipping_outlined,
                background: AppSurface.success.withValues(alpha: 0.12),
                foreground: AppSurface.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      color: AppSurface.text,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    children: [
                      const TextSpan(text: 'Add '),
                      TextSpan(
                        text: '₹${remaining.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(
                        text: ' more for ',
                      ),
                      TextSpan(
                        text: 'FREE delivery',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: AppSurface.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppSurface.subtle,
                valueColor: const AlwaysStoppedAnimation(AppSurface.success),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurgeVariant extends StatelessWidget {
  const _SurgeVariant({required this.multiplier, this.reason});
  final double multiplier;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: AppGradients.flashSale,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadow.dim,
      ),
      child: Row(
        children: [
          _IconBubble(icon: Icons.bolt_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Surge pricing • ${multiplier.toStringAsFixed(1)}x delivery',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                if ((reason ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      reason!,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Atoms ─────────────────────────────────────────────────────────────────

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.20),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: foreground ?? Colors.white, size: 20),
    );
  }
}
