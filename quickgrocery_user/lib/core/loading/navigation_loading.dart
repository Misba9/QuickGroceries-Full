import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/widgets/shimmer_widgets.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_banner.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_cart.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_home.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_order.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_product_card.dart';
import 'package:quickgrocery/core/loading/widgets/skeleton_search.dart';

/// Page-type presets for navigation / first-frame skeletons.
enum LoadingPageKind {
  home,
  search,
  cart,
  checkout,
  orders,
  category,
  vendor,
  product,
}

/// Returns the matching premium skeleton for a destination page.
class NavigationLoading {
  NavigationLoading._();

  static Widget forPage(LoadingPageKind kind) {
    switch (kind) {
      case LoadingPageKind.home:
        return const SkeletonHome();
      case LoadingPageKind.search:
        return const SkeletonSearch();
      case LoadingPageKind.cart:
        return const SkeletonCart();
      case LoadingPageKind.checkout:
        return const SkeletonCheckout();
      case LoadingPageKind.orders:
        return const SkeletonOrder();
      case LoadingPageKind.category:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SkeletonProductGrid(count: 6, childAspectRatio: 0.68),
        );
      case LoadingPageKind.vendor:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonVendor(count: 5),
        );
      case LoadingPageKind.product:
        return const _SkeletonProductDetail();
    }
  }
}

class _SkeletonProductDetail extends StatelessWidget {
  const _SkeletonProductDetail();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerBox(height: 280, radius: AppRadii.lg),
        const SizedBox(height: 16),
        const ShimmerBox(height: 18, width: 220, radius: 6),
        const SizedBox(height: 10),
        const ShimmerBox(height: 14, width: 120, radius: 6),
        const SizedBox(height: 16),
        const ShimmerBox(height: 48, radius: 12),
        const SizedBox(height: 20),
        const ShimmerBox(height: 14, width: 160, radius: 6),
        const SizedBox(height: 12),
        const SkeletonProductRail(count: 3, height: 200),
      ],
    );
  }
}
