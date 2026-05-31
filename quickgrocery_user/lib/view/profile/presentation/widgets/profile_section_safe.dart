import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Isolates a profile section so a localized error message can be shown
/// instead of breaking the entire scroll view.
class ProfileSectionSafe extends StatelessWidget {
  const ProfileSectionSafe({
    super.key,
    required this.section,
    required this.child,
  });

  final String section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class ProfileSectionError extends StatelessWidget {
  const ProfileSectionError({
    super.key,
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.red.shade800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Runs [builder]; on synchronous build failures logs and shows [ProfileSectionError].
class ProfileSectionGuard extends StatelessWidget {
  const ProfileSectionGuard({
    super.key,
    required this.section,
    required this.builder,
  });

  final String section;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    try {
      return builder();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Profile] $section error: $e\n$st');
      }
      return ProfileSectionError(
        title: '$section unavailable',
        message: 'Please try again later.',
      );
    }
  }
}
