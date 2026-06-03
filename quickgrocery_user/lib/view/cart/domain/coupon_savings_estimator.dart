import 'package:quickgrocery/view/cart/data/coupon_service.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/domain/pricing_calculator.dart';

/// Client-side savings preview for listing / best-coupon (server validates on apply).
class CouponSavingsEstimator {
  const CouponSavingsEstimator._();

  static const _calc = PricingCalculator();

  static double estimateTotalSavings({
    required List<CartItem> items,
    required PricingConfig config,
    required CouponEntry entry,
    int? deliveryChargeOverride,
  }) {
    if (items.isEmpty) return 0;
    final without = _calc.compute(
      items: items,
      config: config,
      deliveryChargeOverride: deliveryChargeOverride,
    );
    final withCoupon = _calc.compute(
      items: items,
      config: config,
      coupon: entry.toApplied(),
      deliveryChargeOverride: deliveryChargeOverride,
    );
    return (without.total - withCoupon.total).clamp(0.0, double.infinity);
  }

  /// Picks the coupon with highest estimated cart total reduction (min-order only).
  static CouponEntry? pickBestEligible({
    required List<CouponEntry> coupons,
    required List<CartItem> items,
    required PricingConfig config,
    required double subtotal,
    int? deliveryChargeOverride,
    String? excludeCode,
  }) {
    CouponEntry? best;
    var bestSave = 0.0;

    for (final c in coupons) {
      if (excludeCode != null &&
          c.code.toUpperCase() == excludeCode.toUpperCase()) {
        continue;
      }
      if (!c.isClientEligible(subtotal)) continue;
      final save = estimateTotalSavings(
        items: items,
        config: config,
        entry: c,
        deliveryChargeOverride: deliveryChargeOverride,
      );
      if (save > bestSave) {
        bestSave = save;
        best = c;
      }
    }
    return best;
  }
}

class BestCouponSuggestion {
  const BestCouponSuggestion({
    required this.coupon,
    required this.estimatedSavings,
  });

  final CouponEntry coupon;
  final double estimatedSavings;
}
