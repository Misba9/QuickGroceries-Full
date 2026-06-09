import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// **CartHeader** — clean, sticky-style top bar for the cart screen.
///
/// * Animated back button (scale ripple + haptic on press).
/// * Title + subtitle that swap between "1 item" and "N items".
/// * Coupon icon that nudges the user toward the offers screen.
/// * Subtle bottom shadow so it visually separates from the scroll body.
///
/// Designed to be placed at the top of a `Column` (NOT inside an
/// `AppBar`) so the cart screen owns layout end-to-end and never
/// fights with the Scaffold's app-bar slot.
class CartHeader extends StatelessWidget {
  const CartHeader({
    super.key,
    required this.itemCount,
    required this.onBack,
    required this.onCoupons,
  });

  final int itemCount;
  final VoidCallback onBack;
  final VoidCallback onCoupons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadow.dim,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 12),
          child: Row(
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
                tooltip: 'Back',
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.my_bag,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppSurface.text,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: AppMotion.short,
                      switchInCurve: AppMotion.spring,
                      switchOutCurve: AppMotion.standard,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _subtitle(itemCount),
                        key: ValueKey<int>(itemCount),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppSurface.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _RoundIconButton(
                icon: Icons.local_offer_outlined,
                onTap: onCoupons,
                tooltip: 'Coupons',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(int n) {
    if (n <= 0) return 'Your bag is empty';
    if (n == 1) return '1 item';
    return '$n items';
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkResponse(
          radius: 22,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppSurface.subtle,
            ),
            child: Icon(icon, size: 20, color: AppSurface.text),
          ),
        ),
      ),
    );
  }
}
