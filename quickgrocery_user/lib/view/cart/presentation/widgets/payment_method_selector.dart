import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/checkout/widgets/payment_chip.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_rounded, size: 18, color: AppSurface.text),
            const SizedBox(width: 8),
            Text(
              'Payment method',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppSurface.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PaymentMethod.values.map((m) {
            return PaymentChip(
              label: m.displayName,
              icon: _icon(m),
              selected: m == selected,
              onTap: () => onChanged(m),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Cards, UPI & wallets are powered securely by Razorpay.',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppSurface.textMuted,
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
