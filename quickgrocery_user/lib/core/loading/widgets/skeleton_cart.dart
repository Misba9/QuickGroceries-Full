import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_messages.dart';
import 'package:quickgrocery/core/loading/widgets/animated_category_loader.dart';
import 'package:quickgrocery/core/loading/widgets/shimmer_widgets.dart';

/// Cart page skeleton (banner → bill → line items).
class SkeletonCart extends StatelessWidget {
  const SkeletonCart({super.key, this.showCategoryLoader = true});

  final bool showCategoryLoader;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        if (showCategoryLoader) ...[
          CategoryLoaderBanner(messagePool: LoadingMessages.cart),
          const SizedBox(height: 14),
        ],
        AppShimmer(
          child: Column(
            children: [
              SkeletonBone(height: 60, radius: AppRadii.md),
              const SizedBox(height: 12),
              SkeletonBone(height: 110, radius: AppRadii.md),
              const SizedBox(height: 16),
              for (int i = 0; i < 3; i++) ...[
                _CartItemBone(surface: surface),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemBone extends StatelessWidget {
  const _CartItemBone({required this.surface});

  final AppPalette surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBone(height: 78, width: 78, radius: AppRadii.sm),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(height: 12),
                SizedBox(height: 6),
                SkeletonBone(height: 12, width: 120),
                SizedBox(height: 14),
                SkeletonBone(height: 14, width: 90),
              ],
            ),
          ),
          SizedBox(width: 8),
          SkeletonBone(height: 32, width: 88, radius: 999),
        ],
      ),
    );
  }
}

/// Checkout skeleton — address, slots, payment, bill.
class SkeletonCheckout extends StatelessWidget {
  const SkeletonCheckout({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        CategoryLoaderBanner(messagePool: LoadingMessages.checkout),
        const SizedBox(height: 14),
        AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBone(height: 16, width: 120),
              const SizedBox(height: 10),
              Container(
                height: 96,
                decoration: BoxDecoration(
                  color: surface.shimmerBase,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              const SizedBox(height: 18),
              SkeletonBone(height: 16, width: 140),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(child: SkeletonBone(height: 44, radius: 12)),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBone(height: 44, radius: 12)),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBone(height: 44, radius: 12)),
                ],
              ),
              const SizedBox(height: 18),
              SkeletonBone(height: 16, width: 100),
              const SizedBox(height: 10),
              SkeletonBone(height: 72, radius: AppRadii.md),
              const SizedBox(height: 18),
              SkeletonBone(height: 140, radius: AppRadii.md),
            ],
          ),
        ),
      ],
    );
  }
}
