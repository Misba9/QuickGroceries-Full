import 'package:flutter/material.dart';

import 'package:quickgrocery/core/loading/loading.dart';

/// Skeleton loader for the cart screen — shown briefly during the
/// initial Firestore hydration so the UI never feels frozen.
class CartShimmer extends StatelessWidget {
  const CartShimmer({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonCart();
}
