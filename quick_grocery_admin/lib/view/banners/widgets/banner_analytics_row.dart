import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/view/banners/banner_theme.dart';

/// Aggregated banner analytics stat cards.
class BannerAnalyticsRow extends StatelessWidget {
  const BannerAnalyticsRow({super.key, required this.banners});

  final List<BannerModel> banners;

  @override
  Widget build(BuildContext context) {
    final views = banners.fold<int>(0, (s, b) => s + b.viewCount);
    final clicks = banners.fold<int>(0, (s, b) => s + b.clickCount);
    final orders = banners.fold<int>(0, (s, b) => s + b.orderCount);
    final ctr = views > 0 ? (clicks / views) * 100 : 0.0;

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 600 ? 2 : 4;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: cols == 2 ? 1.6 : 2.2,
          children: [
            _StatCard(
              label: 'Total views',
              value: _fmt(views),
              icon: Icons.visibility_outlined,
            ),
            _StatCard(
              label: 'Clicks',
              value: _fmt(clicks),
              icon: Icons.touch_app_outlined,
            ),
            _StatCard(
              label: 'CTR',
              value: '${ctr.toStringAsFixed(1)}%',
              icon: Icons.percent_outlined,
            ),
            _StatCard(
              label: 'Orders',
              value: _fmt(orders),
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        );
      },
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BannerTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade700),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
