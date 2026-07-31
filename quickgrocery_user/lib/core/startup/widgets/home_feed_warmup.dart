import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_providers.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';

/// Invisible listener that warms the **top half** of Home while the Category
/// Animation is playing.
///
/// Keeps autoDispose stream providers alive so banners / categories / flash /
/// trending / featured / offers are already subscribed before Home mounts.
class HomeFeedWarmup extends ConsumerStatefulWidget {
  const HomeFeedWarmup({super.key});

  @override
  ConsumerState<HomeFeedWarmup> createState() => _HomeFeedWarmupState();
}

class _HomeFeedWarmupState extends ConsumerState<HomeFeedWarmup> {
  bool _logged = false;

  @override
  Widget build(BuildContext context) {
    // Touch top-half providers — starts network + seeds from bootstrap snapshot.
    ref.watch(bannersStreamProvider);
    ref.watch(categoriesStreamProvider);
    ref.watch(flashSaleProductsStreamProvider);
    ref.watch(trendingProductsStreamProvider);
    ref.watch(featuredProductsStreamProvider);
    ref.watch(homeExploreOfferBannersProvider);
    ref.watch(appContentStreamProvider);

    final snap = ref.watch(homeBootstrapSnapshotProvider);
    if (!_logged && snap.hasContent) {
      _logged = true;
      AppStartupLog.milestone(
        'Home top-half warmup',
        'fill=${(snap.topHalfFillRatio * 100).round()}% '
        'banners=${snap.banners.length} cats=${snap.categories.length} '
        'flash=${snap.flashSale.length} trending=${snap.trending.length} '
        'featured=${snap.featured.length}',
      );
    }

    return const SizedBox.shrink();
  }
}
