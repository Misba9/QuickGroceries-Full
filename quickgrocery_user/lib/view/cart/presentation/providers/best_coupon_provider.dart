import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/coupon_savings_estimator.dart';
import 'cart_notifier.dart';
import 'coupons_provider.dart';

/// Highest estimated savings among active coupons (client preview).
final bestCouponSuggestionProvider =
    Provider.autoDispose<BestCouponSuggestion?>((ref) {
  final cart = ref.watch(cartProvider);
  final coupons = ref.watch(couponsStreamProvider).valueOrNull;
  if (cart.isEmpty || coupons == null || coupons.isEmpty) return null;

  final subtotal = cart.bill.subtotal > 0
      ? cart.bill.subtotal
      : cart.items.fold(0.0, (a, i) => a + i.lineTotal);

  final exclude = cart.coupon?.code;
  final best = CouponSavingsEstimator.pickBestEligible(
    coupons: coupons,
    items: cart.items,
    config: cart.pricing,
    subtotal: subtotal,
    excludeCode: exclude,
  );
  if (best == null) return null;

  final save = CouponSavingsEstimator.estimateTotalSavings(
    items: cart.items,
    config: cart.pricing,
    entry: best,
  );
  if (save <= 0) return null;

  return BestCouponSuggestion(coupon: best, estimatedSavings: save);
});
