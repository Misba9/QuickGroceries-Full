import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:quickgrocery_vendor/models/rating_model.dart';
import 'package:quickgrocery_vendor/services/vendor_review_service.dart';
import 'package:quickgrocery_vendor/style/app_color.dart';

class VendorReviewsScreen extends StatefulWidget {
  const VendorReviewsScreen({
    super.key,
    required this.vendorId,
    this.productId,
    this.productName,
  });

  final String vendorId;
  final String? productId;
  final String? productName;

  @override
  State<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

class _VendorReviewsScreenState extends State<VendorReviewsScreen> {
  final _reviewService = VendorReviewService();
  late final Stream<List<RatingModel>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = _reviewService.watchVendorReviews(widget.vendorId);
  }

  List<RatingModel> _filter(List<RatingModel> all) {
    if (widget.productId == null) return all;
    return all.where((r) => r.productId == widget.productId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName ?? 'Customer reviews'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<RatingModel>>(
        stream: _reviewsStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Could not load reviews\n${snap.error}',
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final docs = _filter(snap.data ?? []);
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No reviews yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'Reviews appear when customers rate your products',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final sum = docs.fold<double>(0, (s, r) => s + r.rating);
          final avg = sum / docs.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              avg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('${docs.length} reviews'),
                          ],
                        ),
                      ),
                      RatingBarIndicator(
                        rating: avg,
                        itemBuilder: (_, __) =>
                            const Icon(Icons.star, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((r) => _ReviewCard(review: r, vendorId: widget.vendorId)),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.vendorId});

  final RatingModel review;
  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final date = review.createdAt.toDate();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.userName.isEmpty ? 'Customer' : review.userName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${review.rating.toStringAsFixed(1)}★'),
              ],
            ),
            const SizedBox(height: 4),
            Text(review.productName,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            if (review.orderId.isNotEmpty)
              Text('Order #${review.orderId.length > 8 ? review.orderId.substring(review.orderId.length - 8) : review.orderId}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            if (review.review.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.review),
            ],
            if (review.verifiedPurchase)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Verified purchase',
                    style: TextStyle(color: Colors.blue, fontSize: 11)),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _replyDialog(context, review.id, review),
                child: const Text('Reply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replyDialog(
    BuildContext context,
    String reviewId,
    RatingModel r,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to customer'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Your response…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || controller.text.trim().isEmpty) return;
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('vendorReplyProductReview')
          .call({
        'reviewId': reviewId,
        'vendorId': vendorId,
        'text': controller.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}
