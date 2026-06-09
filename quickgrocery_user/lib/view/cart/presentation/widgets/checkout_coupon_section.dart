import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/device/device_id_service.dart';
import 'package:quickgrocery/core/feedback/show_top_error_toast.dart';
import 'package:quickgrocery/view/cart/data/coupon_service.dart';
import 'package:quickgrocery/view/cart/domain/coupon_savings_estimator.dart';
import 'package:quickgrocery/view/cart/presentation/providers/best_coupon_provider.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/coupons/coupon_screen.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Inline checkout coupon hub — manual code, list, best offer, applied state.
class CheckoutCouponSection extends ConsumerStatefulWidget {
  const CheckoutCouponSection({
    super.key,
    this.checkoutPhone,
    this.deliveryChargeOverride,
  });

  final String? checkoutPhone;
  final int? deliveryChargeOverride;

  @override
  ConsumerState<CheckoutCouponSection> createState() =>
      _CheckoutCouponSectionState();
}

class _CheckoutCouponSectionState extends ConsumerState<CheckoutCouponSection> {
  final _codeController = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  double get _subtotal {
    final cart = ref.read(cartProvider);
    return cart.bill.subtotal > 0
        ? cart.bill.subtotal
        : cart.items.fold(0.0, (a, i) => a + i.lineTotal);
  }

  Future<void> _applyCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty || _applying) return;

    setState(() => _applying = true);
    HapticFeedback.selectionClick();

    final deviceId = await DeviceIdService.getOrCreate();
    final err = await ref.read(cartProvider.notifier).applyCouponValidated(
          code: trimmed,
          validationClient: ref.read(couponValidationClientProvider),
          phone: widget.checkoutPhone,
          deviceId: deviceId,
        );

    if (!mounted) return;
    setState(() => _applying = false);

    if (err != null) {
      showTopErrorToast(context, err);
      return;
    }
    _codeController.clear();
    HapticFeedback.lightImpact();
  }

  Future<void> _applyBest() async {
    final best = ref.read(bestCouponSuggestionProvider);
    if (best == null) {
      showTopErrorToast(context, 'No eligible coupons for this cart');
      return;
    }
    await _applyCode(best.coupon.code);
  }

  void _openAllCoupons() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CouponScreen(checkoutPhone: widget.checkoutPhone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final couponsAsync = ref.watch(couponsStreamProvider);
    final best = ref.watch(bestCouponSuggestionProvider);
    final subtotal = _subtotal;
    final applied = cart.coupon;
    final saved = cart.bill.couponDiscount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.dim,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_rounded, color: AppColor.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.l10n.coupon_section_title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (applied != null) ...[
              _AppliedBanner(
                code: applied.code,
                saved: saved > 0 ? saved : applied.savingsPreview,
                isFirstOrder: applied.isFirstOrderOffer,
                onRemove: () {
                  HapticFeedback.selectionClick();
                  ref.read(cartProvider.notifier).removeCoupon();
                },
              ),
              const SizedBox(height: 14),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: !_applying,
                      decoration: InputDecoration(
                        hintText: 'Enter Coupon Code',
                        isDense: true,
                        filled: true,
                        fillColor: AppSurface.subtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _applying
                        ? null
                        : () => _applyCode(_codeController.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _applying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Apply',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
              if (best != null) ...[
                const SizedBox(height: 12),
                _BestCouponCard(
                  suggestion: best,
                  applying: _applying,
                  onApply: _applyBest,
                ),
              ],
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Available Coupons',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppSurface.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _openAllCoupons,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'View all',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColor.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            couponsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'No coupons available right now',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppSurface.textMuted,
                    ),
                  );
                }
                final sorted = [...list]
                  ..sort((a, b) {
                    final sa = CouponSavingsEstimator.estimateTotalSavings(
                      items: cart.items,
                      config: cart.pricing,
                      entry: a,
                      deliveryChargeOverride: widget.deliveryChargeOverride,
                    );
                    final sb = CouponSavingsEstimator.estimateTotalSavings(
                      items: cart.items,
                      config: cart.pricing,
                      entry: b,
                      deliveryChargeOverride: widget.deliveryChargeOverride,
                    );
                    return sb.compareTo(sa);
                  });
                final visible = sorted.take(4).toList();
                return Column(
                  children: [
                    for (final c in visible)
                      _AvailableCouponTile(
                        coupon: c,
                        subtotal: subtotal,
                        isApplied: applied?.code.toUpperCase() == c.code.toUpperCase(),
                        applying: _applying,
                        onApply: () => _applyCode(c.code),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => Text(
                'Could not load coupons',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppliedBanner extends StatelessWidget {
  const _AppliedBanner({
    required this.code,
    required this.saved,
    required this.isFirstOrder,
    required this.onRemove,
  });

  final String code;
  final double saved;
  final bool isFirstOrder;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coupon Applied ✅',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              TextButton(
                onPressed: onRemove,
                child: Text(
                  'Remove',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          if (saved > 0.25) ...[
            const SizedBox(height: 4),
            Text(
              'You Saved ₹${saved.toStringAsFixed(saved.truncateToDouble() == saved ? 0 : 2)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: const Color(0xFF388E3C),
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            isFirstOrder ? 'First Order · $code' : code,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF558B2F),
            ),
          ),
        ],
      ),
    );
  }
}

class _BestCouponCard extends StatelessWidget {
  const _BestCouponCard({
    required this.suggestion,
    required this.applying,
    required this.onApply,
  });

  final BestCouponSuggestion suggestion;
  final bool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final c = suggestion.coupon;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withValues(alpha: 0.12),
            AppColor.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Coupon Available',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.code} · Save ~₹${suggestion.estimatedSavings.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: applying ? null : onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _AvailableCouponTile extends StatelessWidget {
  const _AvailableCouponTile({
    required this.coupon,
    required this.subtotal,
    required this.isApplied,
    required this.applying,
    required this.onApply,
  });

  final CouponEntry coupon;
  final double subtotal;
  final bool isApplied;
  final bool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final eligible = coupon.isClientEligible(subtotal);
    final disabled = !eligible || applying || isApplied;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isApplied ? const Color(0xFFE8F5E9) : AppSurface.subtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isApplied ? const Color(0xFFA5D6A7) : AppSurface.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coupon.displaySubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppSurface.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (!eligible && coupon.minOrderValue > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Minimum order ₹${coupon.minOrderValue} required',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isApplied)
            Text(
              'Applied',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
                fontSize: 12,
              ),
            )
          else
            OutlinedButton(
              onPressed: disabled ? null : onApply,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.primary,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(color: AppColor.primary.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                'Apply',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
