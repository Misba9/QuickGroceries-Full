import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Shared card shell for profile dashboard sections.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? surface.card : null,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: gradient == null
            ? Border.all(color: surface.border.withValues(alpha: 0.7))
            : null,
        boxShadow: AppShadow.cardOf(context),
      ),
      child: child,
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppSurface.of(context).text,
            ),
          ),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColor.primary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileListTile extends StatelessWidget {
  const ProfileListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppSurface.of(context).textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right_rounded,
                      color: AppSurface.of(context).textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileToggleTile extends StatelessWidget {
  const ProfileToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppSurface.of(context).textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColor.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

IconData addressTypeIcon(String type) {
  switch (type.toUpperCase()) {
    case 'OFFICE':
    case 'WORK':
      return Icons.business_rounded;
    case 'OTHER':
      return Icons.place_rounded;
    default:
      return Icons.home_rounded;
  }
}
