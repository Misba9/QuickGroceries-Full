import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/delivery/domain/delivery_pricing_policy.dart';

/// Shows a lightweight in-app “notification” (SnackBar) when admin changes
/// delivery settings in Firestore — no app restart required.
class DeliveryPricingUpdateListener extends ConsumerStatefulWidget {
  const DeliveryPricingUpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeliveryPricingUpdateListener> createState() =>
      _DeliveryPricingUpdateListenerState();
}

class _DeliveryPricingUpdateListenerState
    extends ConsumerState<DeliveryPricingUpdateListener> {
  String? _lastSignature;

  @override
  Widget build(BuildContext context) {
    ref.listen(pricingConfigProvider, (prev, next) {
      next.whenData((config) {
        final sig = DeliveryPricingPolicy.signature(config);
        if (_lastSignature == null) {
          _lastSignature = sig;
          return;
        }
        if (_lastSignature == sig) return;
        _lastSignature = sig;

        if (kDebugMode) {
          debugPrint('[DeliveryPricingUpdateListener] pricing changed → $sig');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(DeliveryPricingPolicy.snackbarOnRemoteChange(config)),
              duration: const Duration(seconds: 4),
            ),
          );
        });
      });
    });

    return widget.child;
  }
}
