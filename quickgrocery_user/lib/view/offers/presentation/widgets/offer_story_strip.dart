import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/offers/presentation/screens/offer_story_viewer_screen.dart';

/// Instagram-style circular stories for offers.
class OfferStoryStrip extends StatelessWidget {
  const OfferStoryStrip({super.key, required this.offers});

  final List<OfferBannerModel> offers;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        physics: const BouncingScrollPhysics(),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final o = offers[i];
          final thumb = o.thumbnailUrl.isNotEmpty
              ? o.thumbnailUrl
              : o.imageFallbackUrl;
          return _StoryOrb(
            label: o.title.isEmpty ? 'Offer' : o.title,
            imageUrl: thumb,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => OfferStoryViewerScreen(
                    offers: offers,
                    initialIndex: i,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StoryOrb extends StatelessWidget {
  const _StoryOrb({
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  final String label;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.brand(),
                boxShadow: AppShadow.primaryGlow,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppSurface.of(context).subtle,
                child: ClipOval(
                  child: imageUrl.isEmpty
                      ? Icon(Icons.card_giftcard_rounded,
                          color: AppColor.primary)
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        ),
                ),
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppSurface.of(context).textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
