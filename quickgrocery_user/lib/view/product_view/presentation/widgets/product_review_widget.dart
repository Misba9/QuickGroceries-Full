import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/models/rating_model.dart';
import 'package:quickgrocery/view/product_view/domain/rating_repository.dart';

/// Review summary card — average score + per-star distribution bars.
class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({super.key, required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                  color: Colors.black87,
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
                '${summary.total} ${'reviews'.tr()}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
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
        SizedBox(
          width: 14,
          child: Text(
            '$star',
            style: GoogleFonts.poppins(fontSize: 11),
          ),
        ),
        const Icon(Icons.star_rounded, size: 12, color: AppColor.primary),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColor.primary),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 26,
          child: Text(
            '$count',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

/// Single review card.
class ProductReviewCard extends StatelessWidget {
  const ProductReviewCard({super.key, required this.rating});
  final RatingModel rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
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
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rating.userName.isNotEmpty ? rating.userName : 'Anonymous',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RatingBar.builder(
                initialRating: rating.rating,
                ignoreGestures: true,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 12,
                glow: false,
                itemBuilder: (_, __) => const Icon(
                  Icons.star_rounded,
                  color: AppColor.primary,
                ),
                onRatingUpdate: (_) {},
              ),
            ],
          ),
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rating.review,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM d, y').format(rating.createdAt.toDate()),
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
