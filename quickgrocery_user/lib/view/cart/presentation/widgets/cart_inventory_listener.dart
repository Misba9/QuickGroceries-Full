import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/realtime/providers/realtime_providers.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_feedback_provider.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';

/// Subscribes to live product inventory for cart lines and patches the cart.
class CartInventoryListener extends ConsumerStatefulWidget {
  const CartInventoryListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CartInventoryListener> createState() =>
      _CartInventoryListenerState();
}

class _CartInventoryListenerState extends ConsumerState<CartInventoryListener> {
  List<String> _sortedIds = const [];

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final ids = cart.items
        .where((e) => !e.isComboLine)
        .map((e) => e.productId)
        .toSet()
        .toList()
      ..sort();

    if (!_listEquals(_sortedIds, ids)) {
      _sortedIds = List.unmodifiable(ids);
    }

    ref.listen(cartFeedbackProvider, (prev, next) {
      if (next == null || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (next.kind == CartFeedbackKind.error) {
          AppSnackBar.error(next.text, context: context);
        } else {
          AppSnackBar.success(next.text, context: context);
        }
        ref.read(cartFeedbackProvider.notifier).state = null;
      });
    });

    if (_sortedIds.isNotEmpty) {
      ref.listen(
        inventoryStreamProvider(_sortedIds),
        (prev, next) {
          next.whenData((live) {
            ref.read(cartProvider.notifier).applyLiveInventory(live);
          });
        },
      );
    }

    return widget.child;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
