import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/widgets/quantity_stepper.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// **PremiumCartItemCard** — Zepto / Blinkit / Instamart style row.
///
/// Layout (left → right):
/// 1. **Image** — square, 78 dp, soft-grey background, cached + rounded.
/// 2. **Body** — title (2 lines max), unit chip, price + slashed price +
///    `Save ₹X` badge.
/// 3. **Stepper column** — `[-] N [+]` premium pill on top, total price
///    underneath so the user can verify "₹40 × 2 = ₹80" at a glance.
///
/// Extras:
/// * **Out-of-stock state** — red sash + disabled stepper.
/// * **Swipe to remove** — full-width red action with trash icon, with
///   haptic confirm; falls back to long-press → remove for accessibility.
class PremiumCartItemCard extends StatelessWidget {
  const PremiumCartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.onTap,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(
        'cart-${item.productId}-${item.comboGroupKey ?? 'solo'}',
      ),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) => onRemove(),
      child: _CardSurface(
        item: item,
        onIncrement: onIncrement,
        onDecrement: onDecrement,
        onRemove: onRemove,
        onTap: onTap,
      ),
    );
  }
}

// ─── Card surface ─────────────────────────────────────────────────────────

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onTap,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final saved =
        (item.lineSlashedTotal - item.lineTotal).clamp(0.0, double.infinity);
    final outOfStock = item.isUnavailable;
    final stepperMax = item.effectiveMaxQuantity > 0
        ? item.effectiveMaxQuantity
        : null;
    final lineTotal = item.lineTotal;
    final lineMrp = item.lineSlashedTotal;
    final hasSlash = lineMrp > lineTotal + 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.dim,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemImage(
                  url: item.image,
                  outOfStock: outOfStock,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppSurface.text,
                                height: 1.25,
                              ),
                            ),
                          ),
                          _RemoveButton(onTap: onRemove),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (item.unitPerItem.isNotEmpty)
                        _UnitChip(text: item.unitPerItem),
                      if (outOfStock) ...[
                        const SizedBox(height: 6),
                        _OutOfStockChip(),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '₹${_money(lineTotal)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppSurface.text,
                                    height: 1.1,
                                  ),
                                ),
                                if (hasSlash)
                                  Text(
                                    '₹${_money(lineMrp)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: AppSurface.textMuted,
                                      decoration: TextDecoration.lineThrough,
                                      height: 1.1,
                                    ),
                                  ),
                                if (saved > 0.5) _SaveBadge(saved: saved),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IgnorePointer(
                            ignoring: outOfStock,
                            child: Opacity(
                              opacity: outOfStock ? 0.45 : 1,
                              child: QuantityStepper(
                                count: item.itemCount,
                                onIncrement: onIncrement,
                                onDecrement: onDecrement,
                                size: QuantityStepperSize.medium,
                                maxQuantity: stepperMax,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _money(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ─── Image ─────────────────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  const _ItemImage({
    required this.url,
    required this.outOfStock,
  });

  final String url;
  final bool outOfStock;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppSurface.subtle,
              child: CachedImage(url: url, fit: BoxFit.cover),
            ),
            if (outOfStock)
              ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

// ─── Chips ─────────────────────────────────────────────────────────────────

class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppSurface.subtle,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppSurface.textSecondary,
          letterSpacing: 0.2,
          height: 1.2,
        ),
      ),
    );
  }
}

class _OutOfStockChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppSurface.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Item unavailable',
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppSurface.danger,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
    );
  }
}

class _SaveBadge extends StatelessWidget {
  const _SaveBadge({required this.saved});
  final double saved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppSurface.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Save ₹${saved.toStringAsFixed(0)}',
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppSurface.success,
          height: 1.1,
        ),
      ),
    );
  }
}

// ─── Remove button ─────────────────────────────────────────────────────────

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      radius: 22,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 20,
          color: AppSurface.textMuted,
        ),
      ),
    );
  }
}

// ─── Dismiss background (swipe-to-remove) ─────────────────────────────────

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppSurface.danger.withValues(alpha: 0.85),
            AppSurface.danger,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Remove',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.delete_sweep_rounded,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }
}
