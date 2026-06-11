import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';

/// Checkout gate — prompts guest to sign in before placing an order.
class LoginRequiredDialog extends StatelessWidget {
  const LoginRequiredDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    FloatingCartSuppression.acquire();
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const LoginRequiredDialog(),
      );
      return result == true;
    } finally {
      FloatingCartSuppression.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.loginRequiredTitle,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: Text(
        l10n.loginRequiredMessage,
        style: GoogleFonts.poppins(fontSize: 14, height: 1.45),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.loginAction),
        ),
      ],
    );
  }
}
