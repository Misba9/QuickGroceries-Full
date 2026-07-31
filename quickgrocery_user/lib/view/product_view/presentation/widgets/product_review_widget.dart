import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/rating_model.dart';
import 'package:quickgrocery/view/product_view/domain/rating_repository.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({
    super.key,
    required this.summary,
    this.qualityScore,
  });

  final RatingSummary summary;
  final int? qualityScore;

  @override
  Widget build(BuildContext context) {
    final q = qualityScore ?? summary.qualityScorePercent;
    final surface = AppSurface.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: surface.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: surface.text,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              RatingBar.builder(
                initialRating: summary.average,
                allowHalfRating: true,
                ignoreGestures: true,
                itemCount: 5,
                itemSize: 14,
                glow: false,
                itemBuilder: (_, __) => const Icon(
                  Icons.star_rounded,
                  color: AppColor.primary,
                ),
                onRatingUpdate: (_) {},
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.total} ${context.l10n.reviews}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: surface.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$q% quality',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1]
                  .map(
                    (star) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: _DistributionRow(
                        star: star,
                        ratio: summary.ratioFor(star),
                        count: summary.distribution[star] ?? 0,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.star,
    required this.ratio,
    required this.count,
  });

  final int star;
  final double ratio;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 14, child: Text('$star', style: GoogleFonts.poppins(fontSize: 11))),
        const Icon(Icons.star_rounded, size: 12, color: AppColor.primary),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppSurface.of(context).subtle,
              valueColor: const AlwaysStoppedAnimation(AppColor.primary),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 26,
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppSurface.of(context).textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class ProductReviewCard extends StatelessWidget {
  const ProductReviewCard({
    super.key,
    required this.rating,
    this.onHelpful,
    this.onReport,
    this.onEdit,
    this.onDelete,
  });

  final RatingModel rating;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rating.isFeatured
            ? (isDark
                ? Colors.amber.withValues(alpha: 0.12)
                : Colors.amber.shade50)
            : surface.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rating.isFeatured
              ? (isDark ? Colors.amber.shade700 : Colors.amber.shade200)
              : surface.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColor.primary.withValues(alpha: 0.18),
                child: Text(
                  _initials(rating.userName),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.userName.isNotEmpty ? rating.userName : 'Customer',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (rating.verifiedPurchase)
                      Row(
                        children: [
                          Icon(Icons.verified, size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Purchase',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              RatingBar.builder(
                initialRating: rating.rating,
                ignoreGestures: true,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 12,
                glow: false,
                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColor.primary),
                onRatingUpdate: (_) {},
              ),
            ],
          ),
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.review,
              style: GoogleFonts.poppins(fontSize: 12.5, height: 1.35),
            ),
          ],
          if (rating.reviewImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rating.reviewImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: rating.reviewImages[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          if (rating.vendorReply.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppSurface.of(context).subtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller reply',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppSurface.of(context).text,
                    ),
                  ),
                  Text(
                    rating.vendorReply.text,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppSurface.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                DateFormat('MMM d, y').format(rating.createdAt.toDate()),
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: AppSurface.of(context).textMuted,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              if (onHelpful != null)
                TextButton.icon(
                  onPressed: onHelpful,
                  icon: const Icon(Icons.thumb_up_outlined, size: 14),
                  label: Text('Helpful (${rating.helpfulCount})'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: GoogleFonts.poppins(fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}
