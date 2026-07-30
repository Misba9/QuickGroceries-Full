import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_messages.dart';
import 'package:quickgrocery/core/loading/widgets/animated_category_loader.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_product_card.dart';
import 'package:quickgrocery/core/loading/widgets/shimmer_widgets.dart';

/// Compact search loading used inside a [SliverFillRemaining].
class SkeletonSearchFill extends StatelessWidget {
  const SkeletonSearchFill({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        children: [
          const CategoryLoaderBanner(messagePool: LoadingMessages.search),
          const SizedBox(height: 16),
          Expanded(
            child: SkeletonProductGrid(
              count: 4,
              childAspectRatio: 0.68,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full search page skeleton (suggestions + product grid).
class SkeletonSearch extends StatelessWidget {
  const SkeletonSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const CategoryLoaderBanner(messagePool: LoadingMessages.search),
        const SizedBox(height: 16),
        AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBone(width: 110, height: 12),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  5,
                  (_) => const SkeletonBone(
                    width: 88,
                    height: 32,
                    radius: 999,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SkeletonBone(width: 140, height: 12),
              const SizedBox(height: 10),
              for (int i = 0; i < 3; i++) ...[
                const Row(
                  children: [
                    SkeletonBone(width: 18, height: 18, radius: 4),
                    SizedBox(width: 10),
                    Expanded(child: SkeletonBone(height: 12)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 9,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surface.card,
              borderRadius: AppRadii.all(AppRadii.md),
              border: Border.all(color: surface.border),
            ),
            child: const AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: SkeletonBone(height: 120, radius: 12)),
                  SizedBox(height: 10),
                  SkeletonBone(height: 10),
                  SizedBox(height: 6),
                  SkeletonBone(width: 70, height: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
