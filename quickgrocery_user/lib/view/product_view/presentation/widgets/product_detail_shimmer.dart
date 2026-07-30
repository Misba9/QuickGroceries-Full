import 'package:flutter/material.dart';

import 'package:quickgrocery/core/loading/loading.dart';

/// Shimmer skeletons for the product detail screen. Displayed only when
/// the realtime product stream hasn't yielded its first frame yet.
class ProductDetailShimmer extends StatelessWidget {
  const ProductDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationLoading.forPage(LoadingPageKind.product);
  }
}
