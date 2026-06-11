import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/auth/guest_session_provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Subtle banner shown while the user browses without signing in.
class GuestModeBanner extends ConsumerWidget {
  const GuestModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    if (!isGuest) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, size: 16, color: Colors.amber.shade900),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.browsingAsGuest,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
