import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_messages.dart';
import 'package:quickgrocery/core/loading/widgets/animated_category_loader.dart';
import 'package:quickgrocery/core/loading/widgets/shimmer_widgets.dart';

/// Orders list / timeline skeleton.
class SkeletonOrder extends StatelessWidget {
  const SkeletonOrder({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CategoryLoaderBanner(messagePool: LoadingMessages.orders),
        const SizedBox(height: 14),
        for (int i = 0; i < count; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface.card,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: surface.border),
            ),
            child: AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      SkeletonBone(width: 88, height: 12),
                      Spacer(),
                      SkeletonBone(width: 64, height: 22, radius: 999),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (int j = 0; j < 3; j++) ...[
                        if (j > 0) const SizedBox(width: 8),
                        const SkeletonBone(width: 52, height: 52, radius: 10),
                      ],
                      const Spacer(),
                      const SkeletonBone(width: 70, height: 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Timeline dots
                  Row(
                    children: [
                      for (int j = 0; j < 4; j++) ...[
                        if (j > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: surface.shimmerBase,
                            ),
                          ),
                        const SkeletonBone(width: 12, height: 12, radius: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SkeletonBone(width: 160, height: 10),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Order detail timeline skeleton (tracking).
class SkeletonOrderTimeline extends StatelessWidget {
  const SkeletonOrderTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppShimmer(
        child: Column(
          children: [
            SkeletonBone(height: 120, radius: AppRadii.lg),
            const SizedBox(height: 20),
            for (int i = 0; i < 5; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SkeletonBone(width: 16, height: 16, radius: 8),
                      if (i < 4)
                        Container(
                          width: 2,
                          height: 36,
                          color: surface.shimmerBase,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBone(width: 120, height: 12),
                        SizedBox(height: 6),
                        SkeletonBone(width: 180, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
