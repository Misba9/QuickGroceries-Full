import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/product_review_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/reviews/services/review_admin_service.dart';

class ReviewAnalyticsScreen extends StatelessWidget {
  const ReviewAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ReviewAdminService();
    return LayoutBuilder(
      builder: (context, c) {
        final pad = adminResponsivePadding(c.maxWidth);
        return ColoredBox(
          color: const Color(0xFFFFFAF0),
          child: StreamBuilder<List<ProductReviewModel>>(
            stream: service.watchReviews(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reviews = snap.data!;
              final stats = service.analytics(reviews);
              final products = service.productStats(reviews);
              final vendors = service.vendorStats(reviews);

              final highest = [...products]
                ..sort((a, b) => b.average.compareTo(a.average));
              final lowest = [...products]
                ..sort((a, b) => a.average.compareTo(b.average));
              final mostReviewed = [...products]
                ..sort((a, b) => b.count.compareTo(a.count));
              final topVendors = [...vendors]
                ..sort((a, b) => b.average.compareTo(a.average));

              return SingleChildScrollView(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Review Analytics',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    AppSpacing.h15,
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricCard(
                          'Customer satisfaction',
                          '${(stats['satisfaction'] as double).toStringAsFixed(0)}%',
                        ),
                        _MetricCard(
                          'Platform avg',
                          '${(stats['avgRating'] as double).toStringAsFixed(1)}/5',
                        ),
                        _MetricCard('Total reviews', '${stats['total']}'),
                        _MetricCard('Pending', '${stats['pending']}'),
                      ],
                    ),
                    AppSpacing.h15,
                    _RankSection(
                      title: 'Highest rated products',
                      items: highest.take(8).map((p) => _RankRow(
                            label: p.productName,
                            subtitle: '${p.count} reviews',
                            value: '${p.average.toStringAsFixed(1)}★',
                          )),
                    ),
                    AppSpacing.h10,
                    _RankSection(
                      title: 'Lowest rated products',
                      items: lowest.take(8).map((p) => _RankRow(
                            label: p.productName,
                            subtitle: '${p.count} reviews',
                            value: '${p.average.toStringAsFixed(1)}★',
                          )),
                    ),
                    AppSpacing.h10,
                    _RankSection(
                      title: 'Most reviewed products',
                      items: mostReviewed.take(8).map((p) => _RankRow(
                            label: p.productName,
                            subtitle: '${p.average.toStringAsFixed(1)}★ avg',
                            value: '${p.count}',
                          )),
                    ),
                    AppSpacing.h10,
                    _RankSection(
                      title: 'Top vendor quality',
                      items: topVendors.take(8).map((v) => _RankRow(
                            label: v.vendorId,
                            subtitle: '${v.count} reviews',
                            value: '${v.average.toStringAsFixed(1)}★',
                          )),
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
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankSection extends StatelessWidget {
  const _RankSection({required this.title, required this.items});
  final String title;
  final Iterable<Widget> items;

  @override
  Widget build(BuildContext context) {
    final list = items.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Divider(),
            if (list.isEmpty)
              const Text('No approved reviews yet')
            else
              ...list,
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.label,
    required this.subtitle,
    required this.value,
  });

  final String label;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
