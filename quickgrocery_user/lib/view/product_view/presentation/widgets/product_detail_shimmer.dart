import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer skeletons for the product detail screen. Displayed only when
/// the realtime product stream hasn't yielded its first frame yet.
class ProductDetailShimmer extends StatelessWidget {
  const ProductDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(color: Colors.grey.shade200),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: 80, height: 14),
                const SizedBox(height: 10),
                _bar(width: double.infinity, height: 18),
                const SizedBox(height: 8),
                _bar(width: 220, height: 18),
                const SizedBox(height: 16),
                _bar(width: 160, height: 22),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _bar(width: 70, height: 26, radius: 6),
                    const SizedBox(width: 8),
                    _bar(width: 70, height: 26, radius: 6),
                    const SizedBox(width: 8),
                    _bar(width: 70, height: 26, radius: 6),
                  ],
                ),
                const SizedBox(height: 24),
                _bar(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                _bar(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                _bar(width: 240, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({double? width, double? height, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
