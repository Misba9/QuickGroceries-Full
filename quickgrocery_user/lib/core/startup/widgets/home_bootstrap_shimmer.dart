import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading.dart';

/// Full home skeleton shown while [AppBootstrapController] finishes loading.
class HomeBootstrapShimmer extends StatelessWidget {
  const HomeBootstrapShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.of(context).scaffold,
      body: const SafeArea(
        child: SkeletonHome(showCategoryHero: true),
      ),
      bottomNavigationBar: const _TabBarSkeleton(),
    );
  }
}

class _TabBarSkeleton extends StatelessWidget {
  const _TabBarSkeleton();

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Material(
      color: surface.card,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              5,
              (_) => const ShimmerBox(width: 28, height: 28, radius: 8),
            ),
          ),
        ),
      ),
    );
  }
}
