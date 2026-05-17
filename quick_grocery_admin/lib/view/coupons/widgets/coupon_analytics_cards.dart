import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/coupons/models/admin_coupon_model.dart';

class CouponAnalyticsCards extends StatelessWidget {
  const CouponAnalyticsCards({super.key, required this.summary});

  final CouponAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 700 ? 2 : (c.maxWidth < 1100 ? 3 : 5);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              title: 'Total usage',
              value: '${summary.totalUsage}',
              icon: Icons.confirmation_number_outlined,
              color: AppColor.primary,
            ),
            _StatCard(
              title: 'Discount given',
              value: '₹${summary.totalRevenue.toStringAsFixed(0)}',
              icon: Icons.savings_outlined,
              color: Colors.green.shade700,
            ),
            _StatCard(
              title: 'First-order users',
              value: '${summary.firstOrderUsers}',
              icon: Icons.person_add_alt_1,
              color: Colors.blue.shade700,
            ),
            _StatCard(
              title: 'Failed attempts',
              value: '${summary.failedAttempts}',
              icon: Icons.block,
              color: Colors.orange.shade800,
            ),
            _StatCard(
              title: 'Most used',
              value: summary.mostUsedCouponCode,
              subtitle: '${summary.mostUsedCount} times',
              icon: Icons.star_outline,
              color: Colors.purple.shade700,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
