import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/core/firestore/firestore_errors.dart';

/// Non-destructive full-screen state for Firestore stream failures (e.g.
/// `unavailable`). Keeps the app shell stable — no red error screen.
class FirestoreConnectionLost extends StatelessWidget {
  const FirestoreConnectionLost({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = firestoreUserFacingMessage(error);
    return Scaffold(
      backgroundColor: AppSurface.of(context).scaffold,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(24),
          fillMinHeight: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.maintenance_offline,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.retry),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  side: BorderSide(color: AppColor.primary.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  context.l10n.tryAgain,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
