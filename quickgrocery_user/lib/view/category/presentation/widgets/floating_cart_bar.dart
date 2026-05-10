import 'package:flutter/material.dart';

import 'package:quickgrocery/core/widgets/floating_cart_pill.dart';

/// Local re-export so feature code never imports from `core/widgets/`
/// directly. Categories discovery can stack [FloatingCartBar] above its
/// scroll view without coupling to the shared pill implementation.
class FloatingCartBar extends StatelessWidget {
  const FloatingCartBar({
    super.key,
    this.bottomInset = 16,
    this.horizontalInset = 16,
  });

  final double bottomInset;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return FloatingCartPill(
      bottomInset: bottomInset,
      horizontalInset: horizontalInset,
    );
  }
}
