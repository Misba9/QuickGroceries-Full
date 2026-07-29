import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/models/rating_model.dart';
import 'package:quickgrocery/view/product_view/data/review_api_client.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/product_detail_providers.dart';
import 'package:quickgrocery/view/product_view/presentation/screens/write_review_screen.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/view/product_view/presentation/widgets/product_review_widget.dart';

enum ReviewSort { latest, highest, lowest, withPhotos }

class ProductReviewsScreen extends ConsumerStatefulWidget {
  const ProductReviewsScreen({super.key, required this.product});

  final ProductModel product;

  @override
  ConsumerState<ProductReviewsScreen> createState() =>
      _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends ConsumerState<ProductReviewsScreen> {
  ReviewSort _sort = ReviewSort.latest;
  final _api = ReviewApiClient();

  bool _isOwn(RatingModel r) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid.isNotEmpty && r.userId == uid;
  }

  bool _canEdit(RatingModel r) {
    if (!_isOwn(r)) return false;
    return DateTime.now().difference(r.createdAt.toDate()).inHours < 24;
  }

  Future<void> _deleteReview(RatingModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteReviewTitle),
        content: Text(ctx.l10n.deleteReviewBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteReview(r.id);
      if (mounted) {
        AppSnackBar.success(context.l10n.reviewDeleted, context: context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error('$e', context: context);
      }
    }
  }

  List<RatingModel> _sorted(List<RatingModel> list) {
    final copy = [...list];
    switch (_sort) {
      case ReviewSort.highest:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSort.lowest:
        copy.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case ReviewSort.withPhotos:
        copy.retainWhere((r) => r.reviewImages.isNotEmpty);
        break;
      case ReviewSort.latest:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final ratingsAsync = ref.watch(ratingsStreamProvider(widget.product.id));
    final summary = ref.watch(ratingSummaryProvider(widget.product.id));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ratingsAndReviews)),
      body: ratingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(context.l10n.failedToLoadReviews)),
        data: (ratings) {
          final sorted = _sorted(ratings);
          final withPhotos = ratings
              .where((r) => r.reviewImages.isNotEmpty)
              .expand((r) => r.reviewImages)
              .take(12)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ReviewSummaryCard(
                summary: summary,
                qualityScore: widget.product.rating > 0
                    ? ((widget.product.rating / 5) * 100).round()
                    : summary.qualityScorePercent,
              ),
              if (withPhotos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(context.l10n.customerPhotos, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: withPhotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        withPhotos[i],
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReviewSort.values.map((s) {
                    final label = switch (s) {
                      ReviewSort.latest => context.l10n.latest,
                      ReviewSort.highest => context.l10n.highest,
                      ReviewSort.lowest => context.l10n.lowest,
                      ReviewSort.withPhotos => context.l10n.withPhotos,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _sort == s,
                        onSelected: (_) => setState(() => _sort = s),
                        selectedColor: AppColor.primary.withValues(alpha: 0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (sorted.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(context.l10n.noReviewsMatchFilter)),
                )
              else
                ...sorted.map(
                  (r) => ProductReviewCard(
                    rating: r,
                    onHelpful: () => _api.markHelpful(r.id),
                    onReport: () => _api.report(r.id),
                    onEdit: _canEdit(r)
                        ? () async {
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WriteReviewScreen(
                                  product: widget.product,
                                  existingReview: r,
                                ),
                              ),
                            );
                            if (ok == true && mounted) setState(() {});
                          }
                        : null,
                    onDelete: _isOwn(r) ? () => _deleteReview(r) : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
