import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Red error banner at the top of the screen (2.5s, auto-dismiss).
void showTopErrorToast(BuildContext context, String message) {
  if (message.trim().isEmpty) return;

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
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).top -
              64,
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 2500),
        dismissDirection: DismissDirection.up,
      ),
    );
}
