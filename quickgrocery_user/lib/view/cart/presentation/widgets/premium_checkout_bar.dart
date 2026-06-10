import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// **PremiumCheckoutBar** — floating sticky checkout dock at the bottom
/// of the cart screen.
///
/// Layout:
/// ```
/// ┌───────────────────────────────────────────────┐
/// │ N items                                       │
/// │ ₹TOTAL  (savings strip if any)   [ CHECKOUT → ]│
/// └───────────────────────────────────────────────┘
/// ```
///
/// * Top hairline divider so the scrollable content above feels capped.
/// * Bottom inset uses [MediaQuery.padding] + padding so the home indicator
///   never overlaps the CTA (works inside [Scaffold.bottomNavigationBar]).
/// * Disabled state when min order isn't met or items are out of stock —
///   the CTA dims and the helper line above turns red.
/// * Loading state shows a spinner inside the button instead of label.
/// * Prefer [Scaffold.bottomNavigationBar] so the keyboard shrinks the body
///   instead of squeezing this bar inside a [Column].
class PremiumCheckoutBar extends StatelessWidget {
  const PremiumCheckoutBar({
    super.key,
    required this.total,
    required this.itemCount,
    required this.savings,
    required this.enabled,
    required this.isLoading,
    required this.onCheckout,
    this.helperText,
    this.helperIsError = false,
    this.buttonText = 'Proceed to Checkout',
    this.loadingLabel = 'Loading...',
  });

  final double total;
  final int itemCount;
  final double savings;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onCheckout;
  final String buttonText;
  final String loadingLabel;

  /// Tiny line of text rendered above the totals row — used to surface
  /// "min order ₹100, add ₹30 more" or "Some items are out of stock".
  final String? helperText;
  final bool helperIsError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppSurface.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if ((helperText ?? '').isNotEmpty) ...[
                _Helper(text: helperText!, isError: helperIsError),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedTotal(value: total),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _itemsLabel(itemCount),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: AppSurface.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            if (savings > 0.5)
                              Text(
                                'Saved ₹${savings.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: AppSurface.success,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CheckoutButton(
                    label: buttonText,
                    loadingLabel: loadingLabel,
                    enabled: enabled && !isLoading,
                    isLoading: isLoading,
                    onTap: () {
                      if (isLoading) return;
                      HapticFeedback.mediumImpact();
                      onCheckout();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _itemsLabel(int n) => n == 1 ? '1 item in cart' : '$n items in cart';
}

/// Reusable compact sticky payment bar shared by cart and checkout.
class StickyCheckoutBar extends PremiumCheckoutBar {
  const StickyCheckoutBar({
    super.key,
    required double totalAmount,
    required super.itemCount,
    required super.savings,
    required super.buttonText,
    required VoidCallback onTap,
    super.enabled = true,
    super.isLoading = false,
    super.helperText,
    super.helperIsError,
    super.loadingLabel = 'Loading...',
  }) : super(total: totalAmount, onCheckout: onTap);
}

// ─── Pieces ────────────────────────────────────────────────────────────────

class _Helper extends StatelessWidget {
  const _Helper({required this.text, required this.isError});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppSurface.danger : AppSurface.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTotal extends StatelessWidget {
  const _AnimatedTotal({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.short,
      switchInCurve: AppMotion.spring,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Text(
        '₹${value.toStringAsFixed(0)}',
        key: ValueKey<int>(value.round()),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 19,
          color: AppSurface.text,
          letterSpacing: -0.4,
          height: 1.1,
        ),
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton({
    required this.label,
    required this.loadingLabel,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final String loadingLabel;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.short,
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppGradients.brand(),
              borderRadius: BorderRadius.circular(14),
              boxShadow: enabled ? AppShadow.primaryGlow : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Center(
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            loadingLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
