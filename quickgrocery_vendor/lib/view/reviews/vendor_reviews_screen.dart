import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:quickgrocery_vendor/models/rating_model.dart';
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
  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('ratings')
        .where('vendor_id', isEqualTo: widget.vendorId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName ?? 'Customer reviews'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snap.data!.docs;
          if (widget.productId != null) {
            docs = docs
                .where((d) => d.data()['product_id'] == widget.productId)
                .toList();
          }
          docs = docs.where((d) {
            final status = (d.data()['status'] ?? 'approved').toString();
            return status == 'approved' && d.data()['hidden'] != true;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No reviews yet'));
          }

          double sum = 0;
          for (final d in docs) {
            sum += (d.data()['rating'] as num?)?.toDouble() ?? 0;
          }
          final avg = sum / docs.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text('Average ${avg.toStringAsFixed(1)} / 5'),
                  subtitle: Text('${docs.length} reviews'),
                  trailing: RatingBarIndicator(
                    rating: avg,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final r = RatingModel.fromFirestore(doc.data(), doc.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(r.productName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.review, maxLines: 3, overflow: TextOverflow.ellipsis),
                        if (r.verifiedPurchase)
                          const Text(
                            'Verified Purchase',
                            style: TextStyle(color: Colors.blue, fontSize: 11),
                          ),
                      ],
                    ),
                    trailing: Text('${r.rating}★'),
                    onTap: () => _replyDialog(doc.id, r),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _replyDialog(String reviewId, RatingModel r) async {
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || controller.text.trim().isEmpty) return;
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('vendorReplyProductReview')
          .call({
        'reviewId': reviewId,
        'vendorId': widget.vendorId,
        'text': controller.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}
