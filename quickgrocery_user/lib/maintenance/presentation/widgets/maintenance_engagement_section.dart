import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_config.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Coupons, offers, referral during downtime.
class MaintenanceEngagementSection extends StatelessWidget {
  const MaintenanceEngagementSection({
    super.key,
    required this.engagement,
    required this.locale,
    required this.textColor,
  });

  final MaintenanceEngagement engagement;
  final String locale;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (!engagement.showCoupons &&
        !engagement.showOffers &&
        !engagement.showReferral) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.maintenance_while_you_wait,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        if (engagement.showOffers && engagement.offerHeadline.isNotEmpty)
          _Card(
            icon: Icons.local_offer_rounded,
            title: engagement.offerHeadline,
            subtitle: context.l10n.maintenance_offers_hint,
            textColor: textColor,
          ),
        if (engagement.showCoupons && engagement.couponCodes.isNotEmpty)
          _Card(
            icon: Icons.confirmation_number_rounded,
            title: context.l10n.maintenance_coupons,
            subtitle: engagement.couponCodes.join(' · '),
            textColor: textColor,
          ),
        if (engagement.showReferral)
          _Card(
            icon: Icons.card_giftcard_rounded,
            title: context.l10n.maintenance_referral,
            subtitle: context.l10n.maintenance_referral_hint,
            textColor: textColor,
          ),
        if (engagement.showComingSoon)
          _Card(
            icon: Icons.shopping_bag_outlined,
            title: context.l10n.maintenance_coming_soon,
            subtitle: context.l10n.maintenance_coming_soon_hint,
            textColor: textColor,
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
