import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/user/cod_eligibility.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/checkout/widgets/payment_chip.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.codEligibility = CodEligibility.allowed,
    this.hideUnavailableCod = false,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;
  final CodEligibility codEligibility;

  /// When true, hide COD entirely instead of showing it disabled.
  final bool hideUnavailableCod;

  @override
  Widget build(BuildContext context) {
    final codAllowed = codEligibility.isCodAllowed;
    final methods = PaymentMethod.values.where((m) {
      if (m == PaymentMethod.cod && !codAllowed && hideUnavailableCod) {
        return false;
      }
      return true;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_rounded, size: 18, color: AppSurface.of(context).text),
            SizedBox(width: 8),
            Text(
              'Payment method',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppSurface.of(context).text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods.map((m) {
            final isCod = m == PaymentMethod.cod;
            final enabled = !isCod || codAllowed;
            return PaymentChip(
              label: m.displayName,
              icon: _icon(m),
              selected: m == selected,
              enabled: enabled,
              onTap: () => onChanged(m),
            );
          }).toList(),
        ),
        if (!codAllowed) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.35)),
            ),
            child: Text(
              codEligibility.blockedMessage,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9A3412),
                height: 1.35,
              ),
            ),
          ),
        ],
        SizedBox(height: 8),
        Text(
          'Cards, UPI & wallets are powered securely by Razorpay.',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppSurface.of(context).textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  IconData _icon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cod:
        return Icons.payments_outlined;
      case PaymentMethod.upi:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.wallet:
        return Icons.wallet_travel_outlined;
    }
  }
}
