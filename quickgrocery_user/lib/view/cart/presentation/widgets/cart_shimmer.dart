import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// Skeleton loader for the cart screen — shown briefly during the
/// initial Firestore hydration so the UI never feels frozen.
///
/// Mirrors the eventual layout (banner → bill → 3 item rows) so the
/// transition into the real content is purely a fade with no shift.
class CartShimmer extends StatelessWidget {
  const CartShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9E9EE),
      highlightColor: const Color(0xFFF8F8FB),
      period: const Duration(milliseconds: 1100),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: [
          _box(height: 60, radius: AppRadii.md),
          const SizedBox(height: 12),
          _box(height: 110, radius: AppRadii.md),
          const SizedBox(height: 16),
          for (int i = 0; i < 3; i++) ...[
            _itemRow(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _itemRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(height: 78, width: 78, radius: AppRadii.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _box(height: 12, radius: 6),
                const SizedBox(height: 6),
                _box(height: 12, width: 120, radius: 6),
                const SizedBox(height: 14),
                _box(height: 14, width: 90, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _box(height: 32, width: 88, radius: 999),
        ],
      ),
    );
  }

  Widget _box({double height = 14, double? width, double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
