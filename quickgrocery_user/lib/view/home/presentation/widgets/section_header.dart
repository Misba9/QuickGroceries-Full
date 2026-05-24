import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/view/app_content/presentation/widgets/animated_app_heading.dart';

/// Blinkit / Zepto-style section title row — title left, optional action right.
///
/// Horizontal inset comes from the parent ([Responsive.gutter] on screens).
/// Do not wrap in [Center]; use inside a [Column] with
/// [CrossAxisAlignment.start].
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;
  final bool compact;

  /// Standard horizontal inset when a section is not already gutter-padded.
  static double inset(BuildContext context) => Responsive.of(context).gutter();

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final titleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: compact ? 16 : 17,
      color: AppSurface.textPrimary,
      height: 1.2,
      letterSpacing: -0.25,
    );
    final subtitleStyle = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppSurface.textMuted,
      height: 1.25,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(0, compact ? 4 : 6, 0, compact ? 8 : 10),
      child: Row(
        crossAxisAlignment:
            hasSubtitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: AppGradients.brand(),
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppShadow.dim,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedAppHeading(
                    text: title,
                    isLoading: isLoading,
                    compact: compact,
                    style: titleStyle,
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: subtitleStyle,
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            Padding(
              padding: EdgeInsets.only(top: hasSubtitle ? 2 : 0),
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
