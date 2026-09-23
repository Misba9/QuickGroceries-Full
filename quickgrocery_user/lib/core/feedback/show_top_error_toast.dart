import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact floating error snackbar (2.5s, auto-dismiss).
///
/// Do **not** use a near-full-screen `bottom` margin to fake a top toast.
/// That overflows nested Scaffolds (Cart checkout dock, tab shell) and
/// throws "Floating SnackBar presented off screen", which then cascades
/// into layout / semantics / deactivated-element errors.
void showTopErrorToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 2500),
}) {
  if (message.trim().isEmpty) return;
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
      ),
    );
}
