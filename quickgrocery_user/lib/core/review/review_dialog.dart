import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Result of the initial "Enjoyed your order?" prompt.
enum ReviewPromptAction {
  rateNow,
  later,
  noThanks,
}

/// Platform-adaptive entry dialog for the order-experience review flow.
Future<ReviewPromptAction?> showOrderReviewPromptDialog(
  BuildContext context,
) {
  final useCupertino = Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.macOS;

  if (useCupertino) {
    return showCupertinoDialog<ReviewPromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('⭐ Enjoyed your order?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            "We'd love to hear your feedback. Your review helps us improve our service.",
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, ReviewPromptAction.noThanks),
            child: const Text('No Thanks'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, ReviewPromptAction.later),
            child: const Text('Later'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, ReviewPromptAction.rateNow),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  return showGeneralDialog<ReviewPromptAction>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Order review',
    barrierColor: Colors.black54,
    transitionDuration: AppMotion.medium,
    pageBuilder: (ctx, anim, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: Center(
            child: _MaterialReviewPromptCard(
              onRateNow: () => Navigator.pop(ctx, ReviewPromptAction.rateNow),
              onLater: () => Navigator.pop(ctx, ReviewPromptAction.later),
              onNoThanks: () =>
                  Navigator.pop(ctx, ReviewPromptAction.noThanks),
            ),
          ),
        ),
      );
    },
  );
}

class _MaterialReviewPromptCard extends StatelessWidget {
  const _MaterialReviewPromptCard({
    required this.onRateNow,
    required this.onLater,
    required this.onNoThanks,
  });

  final VoidCallback onRateNow;
  final VoidCallback onLater;
  final VoidCallback onNoThanks;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadow.raised,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                '⭐ Enjoyed your order?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'd love to hear your feedback. Your review helps us improve our service.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                  color: AppSurface.of(context).textMuted,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRateNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  child: Text(
                    'Rate Now',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: onLater,
                child: Text(
                  'Later',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppSurface.of(context).textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: onNoThanks,
                child: Text(
                  'No Thanks',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: AppSurface.of(context).textMuted,
                    fontSize: 13,
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

/// Step 1: star selection. Returns 1–5 or null if cancelled.
Future<int?> showStarRatingDialog(BuildContext context) {
  final useCupertino = Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.macOS;

  if (useCupertino) {
    return showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => const _CupertinoStarSheet(),
    );
  }

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _MaterialStarSheet(),
  );
}

class _MaterialStarSheet extends StatefulWidget {
  const _MaterialStarSheet();

  @override
  State<_MaterialStarSheet> createState() => _MaterialStarSheetState();
}

class _MaterialStarSheetState extends State<_MaterialStarSheet> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How was your experience?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a star to rate',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppSurface.of(context).textMuted,
            ),
          ),
          SizedBox(height: 16),
          _StarRow(
            rating: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating < 1
                  ? null
                  : () => Navigator.pop(context, _rating),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppSurface.of(context).textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _CupertinoStarSheet extends StatefulWidget {
  const _CupertinoStarSheet();

  @override
  State<_CupertinoStarSheet> createState() => _CupertinoStarSheetState();
}

class _CupertinoStarSheetState extends State<_CupertinoStarSheet> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How was your experience?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 14),
            _StarRow(
              rating: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _rating < 1
                    ? null
                    : () => Navigator.pop(context, _rating),
                child: const Text('Continue'),
              ),
            ),
            CupertinoButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        final selected = star <= rating;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: selected ? 1.15 : 1.0),
          duration: AppMotion.short,
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: IconButton(
            onPressed: () => onChanged(star),
            iconSize: 40,
            icon: Icon(
              selected ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.amber,
            ),
          ),
        );
      }),
    );
  }
}

/// Low-rating feedback form. Returns submitted text or null if cancelled.
Future<String?> showInternalFeedbackForm(
  BuildContext context, {
  required int rating,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FeedbackFormSheet(rating: rating),
  );
}

class _FeedbackFormSheet extends StatefulWidget {
  const _FeedbackFormSheet({required this.rating});

  final int rating;

  @override
  State<_FeedbackFormSheet> createState() => _FeedbackFormSheetState();
}

class _FeedbackFormSheetState extends State<_FeedbackFormSheet> {
  final _controller = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us what went wrong',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your ${widget.rating}-star feedback stays private and helps us improve.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppSurface.of(context).textMuted,
              ),
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              child: _StarRow(rating: widget.rating, onChanged: (_) {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Share details (optional)',
                // Screenshot attachment is future-ready — reserved UI hint.
                helperText: 'Screenshots coming soon',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () {
                      setState(() => _submitting = true);
                      Navigator.pop(context, _controller.text.trim());
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
              child: Text(
                'Submit feedback',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppSurface.of(context).textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optional follow-up when the native review sheet is unavailable.
Future<bool> showOpenStoreReviewDialog(BuildContext context) async {
  final useCupertino = Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.macOS;

  if (useCupertino) {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Leave a review?'),
        content: const Text(
          'Would you mind rating us on the App Store? It only takes a moment.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open App Store'),
          ),
        ],
      ),
    );
    return result == true;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Leave a review?',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Would you mind rating us on the Play Store? It only takes a moment.',
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Open Play Store'),
        ),
      ],
    ),
  );
  return result == true;
}
