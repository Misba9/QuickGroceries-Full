import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/models/product.dart';

class ProductBadgesRow extends StatelessWidget {
  const ProductBadgesRow({
    super.key,
    required this.product,
    this.maxBadges = 2,
    this.compact = true,
  });

  final ProductModel product;
  final int maxBadges;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badges = _resolveBadges(product);
    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: badges.take(maxBadges).map((b) => _BadgeChip(data: b, compact: compact)).toList(),
    );
  }

  static List<_BadgeData> _resolveBadges(ProductModel p) {
    final out = <_BadgeData>[];
    if (p.isOutOfStock) {
      out.add(_BadgeData('Out of Stock', Colors.orange.shade800, Icons.block));
    }
    if (p.isFlashSaleLive) {
      out.add(_BadgeData('Flash Sale', Colors.red.shade600, Icons.bolt));
    }
    if (p.isTrending) {
      out.add(_BadgeData('Trending', Colors.deepOrange, Icons.whatshot_outlined));
    }
    if (p.isMostSold) {
      out.add(_BadgeData('Best Seller', Colors.amber.shade800, Icons.emoji_events_outlined));
    }
    if (p.isRecommended) {
      out.add(_BadgeData('Recommended', Colors.blue.shade700, Icons.thumb_up_alt_outlined));
    }
    if (p.isLimitedStock) {
      out.add(_BadgeData('Limited', Colors.orange.shade800, Icons.inventory_2_outlined));
    }
    if (p.isNewArrival) {
      out.add(_BadgeData('New', Colors.green.shade700, Icons.fiber_new_rounded));
    }
    if (p.isTodaysBest) {
      out.add(_BadgeData("Today's Best", Colors.purple.shade700, Icons.star_rounded));
    }
    if (p.isPremium) {
      out.add(_BadgeData('Premium', Colors.indigo, Icons.diamond_outlined));
    }
    return out;
  }
}

class _BadgeData {
  const _BadgeData(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.data, required this.compact});
  final _BadgeData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: data.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: compact ? 10 : 12, color: data.color),
          const SizedBox(width: 3),
          Text(
            data.label,
            style: GoogleFonts.poppins(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: data.color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
