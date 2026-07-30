import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';

/// **PremiumBillCard** — modern collapsible bill summary inspired by
/// Zepto / Blinkit / Instamart "Bill details" card.
///
/// Surface design:
/// * 16-radius white card with [AppShadow.dim].
/// * Receipt icon + bold "Bill details" header + chevron toggle.
/// * Sticky savings banner at the top when totalSavings > 0.
/// * Collapsed state shows just the "To pay" total + savings strip.
/// * Expanded state shows every line (item total, savings, coupon,
///   delivery, surge, handling, platform fee, tax) with subtle dividers.
/// * Total updates with a smooth crossfade so the user sees price moves.
class PremiumBillCard extends StatefulWidget {
  const PremiumBillCard({
    super.key,
    required this.bill,
    required this.pricing,
    this.couponLabel,
    this.initiallyExpanded = true,
  });

  final BillBreakdown bill;
  final PricingConfig pricing;
  final String? couponLabel;
  final bool initiallyExpanded;

  @override
  State<PremiumBillCard> createState() => _PremiumBillCardState();
}

class _PremiumBillCardState extends State<PremiumBillCard> {
  late bool _expanded = widget.initiallyExpanded;

  static String _formatBillSyncTime(DateTime d) {
    final l = d.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final pricing = widget.pricing;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.of(context).border),
        boxShadow: AppShadow.dim,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bill.totalSavings > 0.5)
            _SavingsStrip(amount: bill.totalSavings),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppSurface.of(context).subtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: AppSurface.of(context).textSecondary,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppSurface.of(context).text,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pricing.settingsUpdatedAt != null
                                      ? 'Live pricing · ${_formatBillSyncTime(pricing.settingsUpdatedAt!)}'
                                      : 'Live pricing',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppSurface.of(context).textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppMotion.short,
                      curve: AppMotion.emphasized,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppSurface.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.short,
            curve: AppMotion.emphasized,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _Breakdown(
                    bill: bill,
                    pricing: pricing,
                    couponLabel: widget.couponLabel,
                  )
                : SizedBox.shrink(),
          ),
          _Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Text(
                  'To pay',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppSurface.of(context).text,
                  ),
                ),
                const Spacer(),
                _AnimatedTotal(value: bill.total),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated total ───────────────────────────────────────────────────────

class _AnimatedTotal extends StatelessWidget {
  const _AnimatedTotal({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: AppMotion.short,
      curve: AppMotion.emphasized,
      builder: (context, v, _) => Text(
        '₹${v.toStringAsFixed(0)}',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: AppSurface.of(context).text,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// ─── Savings strip ────────────────────────────────────────────────────────

class _SavingsStrip extends StatelessWidget {
  const _SavingsStrip({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppSurface.of(context).success.withValues(alpha: 0.10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.savings_rounded,
            size: 16,
            color: AppSurface.of(context).success,
          ),
          SizedBox(width: 8),
          Text(
            'You save ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppSurface.of(context).success,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppSurface.of(context).success,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            ' on this order',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppSurface.of(context).success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Breakdown ────────────────────────────────────────────────────────────

class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.bill,
    required this.pricing,
    required this.couponLabel,
  });

  final BillBreakdown bill;
  final PricingConfig pricing;
  final String? couponLabel;

  @override
  Widget build(BuildContext context) {
    final rows = <_RowSpec>[
      _RowSpec(
        label: 'Item total',
        value: '₹${bill.subtotal.toStringAsFixed(0)}',
      ),
      if (bill.itemSavings > 0.25)
        _RowSpec(
          label: 'You saved on MRP',
          value: '₹${bill.itemSavings.toStringAsFixed(0)}',
          accent: AppSurface.of(context).success,
        ),
      if (bill.couponDiscount > 0.25)
        _RowSpec(
          label: couponLabel ?? 'Coupon Discount',
          value: '-₹${bill.couponDiscount.toStringAsFixed(0)}',
          accent: AppSurface.of(context).success,
        ),
      _RowSpec(
        label: 'Delivery fee',
        value: bill.isFreeDelivery
            ? 'FREE'
            : '₹${bill.deliveryFee.toStringAsFixed(0)}',
        valueStrike: bill.isFreeDelivery && bill.deliveryFee > 0,
        valueStrikeText: bill.isFreeDelivery && bill.deliveryFee > 0
            ? '₹${bill.deliveryFee.toStringAsFixed(0)}'
            : null,
        sub: bill.isFreeDelivery
            ? 'Free above ₹${pricing.freeDeliveryThreshold}'
            : null,
        accent: bill.isFreeDelivery ? AppSurface.of(context).success : null,
      ),
      if (bill.surgeFee > 0.05)
        _RowSpec(
          label: 'Surge fee',
          value: '+ ₹${bill.surgeFee.toStringAsFixed(0)}',
          sub: pricing.surgeReason,
          accent: const Color(0xFFE17500),
        ),
      _RowSpec(
        label: 'Handling charge',
        value: '₹${bill.handlingCharge.toStringAsFixed(0)}',
      ),
      _RowSpec(
        label: 'Platform fee',
        value: '₹${bill.platformFee.toStringAsFixed(0)}',
      ),
      if (bill.tax > 0.05)
        _RowSpec(
          label: 'Tax (${pricing.taxPercent.toStringAsFixed(1)}%)',
          value: '₹${bill.tax.toStringAsFixed(0)}',
        ),
      if (bill.codConvenienceFee > 0.05)
        _RowSpec(
          label: bill.codFeeDescription.isNotEmpty
              ? bill.codFeeDescription
              : 'COD Convenience Fee',
          value: '₹${bill.codConvenienceFee.toStringAsFixed(0)}',
        ),
      if (bill.deliveryPartnerTip > 0.05)
        _RowSpec(
          label: 'Delivery Partner Tip',
          value: '₹${bill.deliveryPartnerTip.toStringAsFixed(0)}',
          accent: const Color(0xFFE6A800),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _BillRow(spec: rows[i]),
            if (i < rows.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.spec});
  final _RowSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                spec.label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppSurface.of(context).textSecondary,
                  height: 1.3,
                ),
              ),
              if ((spec.sub ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Text(
                    spec.sub!,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppSurface.of(context).textMuted,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (spec.valueStrike && (spec.valueStrikeText ?? '').isNotEmpty) ...[
          Text(
            spec.valueStrikeText!,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppSurface.of(context).textMuted,
              decoration: TextDecoration.lineThrough,
              height: 1.3,
            ),
          ),
          SizedBox(width: 6),
        ],
        Text(
          spec.value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: spec.accent ?? AppSurface.of(context).text,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: 14),
      color: AppSurface.of(context).border,
    );
  }
}

class _RowSpec {
  const _RowSpec({
    required this.label,
    required this.value,
    this.sub,
    this.accent,
    this.valueStrike = false,
    this.valueStrikeText,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? accent;
  final bool valueStrike;
  final String? valueStrikeText;
}
