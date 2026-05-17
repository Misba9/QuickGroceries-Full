import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/product_review_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/reviews/review_admin_client.dart';
import 'package:quick_grocery_admin/view/reviews/services/review_admin_service.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  final _service = ReviewAdminService();
  final _client = ReviewAdminClient();
  final _search = TextEditingController();
  ReviewAdminFilter _filter = ReviewAdminFilter.all;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _moderate(ProductReviewModel r, String action) async {
    setState(() => _busy = true);
    try {
      await _client.moderate(reviewId: r.id, action: action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review ${action}d')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reply(ProductReviewModel r) async {
    final controller = TextEditingController(text: r.vendorReply);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true) return;
    await _client.moderate(
      reviewId: r.id,
      action: 'approve',
      adminReply: controller.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = adminResponsivePadding(c.maxWidth);
        return ColoredBox(
          color: const Color(0xFFFFFAF0),
          child: StreamBuilder<List<ProductReviewModel>>(
            stream: _service.watchReviews(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data!;
              final stats = _service.analytics(all);
              final filtered = _service.filter(
                all,
                f: _filter,
                search: _search.text,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Review Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.h15,
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatChip('Avg rating', '${(stats['avgRating'] as double).toStringAsFixed(1)}/5'),
                        _StatChip('Total', '${stats['total']}'),
                        _StatChip('Pending', '${stats['pending']}'),
                        _StatChip('Reported', '${stats['reported']}'),
                      ],
                    ),
                    AppSpacing.h15,
                    WrapperWidget(
                      child: Column(
                        children: [
                          TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              hintText: 'Search product, user, review…',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          AppSpacing.h10,
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ReviewAdminFilter.values.map((f) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(_filterLabel(f)),
                                    selected: _filter == f,
                                    onSelected: (_) => setState(() => _filter = f),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (_busy) const LinearProgressIndicator(),
                          AppSpacing.h10,
                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No reviews match filters'),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (_, i) => _ReviewRow(
                                review: filtered[i],
                                onApprove: () => _moderate(filtered[i], 'approve'),
                                onReject: () => _moderate(filtered[i], 'reject'),
                                onHide: () => _moderate(filtered[i], 'hide'),
                                onFeature: () => _moderate(
                                  filtered[i],
                                  filtered[i].isFeatured ? 'unfeature' : 'feature',
                                ),
                                onReply: () => _reply(filtered[i]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _filterLabel(ReviewAdminFilter f) {
    switch (f) {
      case ReviewAdminFilter.all:
        return 'All';
      case ReviewAdminFilter.pending:
        return 'Pending';
      case ReviewAdminFilter.lowRating:
        return 'Low ★';
      case ReviewAdminFilter.highRating:
        return 'High ★';
      case ReviewAdminFilter.reported:
        return 'Reported';
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: AppColor.primary,
        child: Text(value, style: const TextStyle(fontSize: 10, color: Colors.black)),
      ),
      label: Text(label),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.review,
    required this.onApprove,
    required this.onReject,
    required this.onHide,
    required this.onFeature,
    required this.onReply,
  });

  final ProductReviewModel review;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onHide;
  final VoidCallback onFeature;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(
        '${review.productName} · ${review.rating.toStringAsFixed(1)}★',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${review.userName} · ${review.status} · reported ${review.reportedCount}'),
          if (review.review.isNotEmpty) Text(review.review, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'approve':
              onApprove();
              break;
            case 'reject':
              onReject();
              break;
            case 'hide':
              onHide();
              break;
            case 'feature':
              onFeature();
              break;
            case 'reply':
              onReply();
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'approve', child: Text('Approve')),
          PopupMenuItem(value: 'reject', child: Text('Reject')),
          PopupMenuItem(value: 'hide', child: Text('Hide')),
          PopupMenuItem(value: 'feature', child: Text('Pin / Unpin')),
          PopupMenuItem(value: 'reply', child: Text('Reply')),
        ],
      ),
    );
  }
}
