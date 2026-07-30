import 'cart_models.dart';

/// Client-side projection of COD Convenience Fee (server recalculates on place).
class CodFeeCalculator {
  const CodFeeCalculator();

  /// Returns the fee to add when [paymentMethod] is COD, else 0.
  double compute({
    required PricingConfig config,
    required PaymentMethod paymentMethod,
    required double orderAmountAfterCoupon,
    String? userId,
    String? city,
    List<String> vendorIds = const [],
    List<String> categories = const [],
  }) {
    if (paymentMethod != PaymentMethod.cod) return 0;
    if (!config.codFeeEnabled) return 0;

    final feeAmount = config.codFeeAmount;
    if (feeAmount <= 0) return 0;

    final amount = orderAmountAfterCoupon.clamp(0.0, double.infinity);
    if (config.codFeeMinimumOrderAmount > 0 &&
        amount < config.codFeeMinimumOrderAmount) {
      return 0;
    }
    if (config.codFeeMaximumOrderAmount > 0 &&
        amount > config.codFeeMaximumOrderAmount) {
      return 0;
    }
    if (config.freeCodAboveAmount > 0 &&
        amount >= config.freeCodAboveAmount) {
      return 0;
    }
    if (!_targetingMatches(
      config: config,
      userId: userId,
      city: city,
      vendorIds: vendorIds,
      categories: categories,
    )) {
      return 0;
    }

    return double.parse(feeAmount.toStringAsFixed(2));
  }

  static bool _targetingMatches({
    required PricingConfig config,
    String? userId,
    String? city,
    required List<String> vendorIds,
    required List<String> categories,
  }) {
    switch (config.codFeeApplicableTo) {
      case 'all':
        return true;
      case 'users':
        final uid = (userId ?? '').trim().toLowerCase();
        if (uid.isEmpty || config.codFeeApplicableUsers.isEmpty) return false;
        return config.codFeeApplicableUsers
            .map((e) => e.trim().toLowerCase())
            .contains(uid);
      case 'cities':
        final c = (city ?? '').trim().toLowerCase();
        if (c.isEmpty || config.codFeeApplicableCities.isEmpty) return false;
        return config.codFeeApplicableCities
            .map((e) => e.trim().toLowerCase())
            .contains(c);
      case 'vendors':
        if (config.codFeeApplicableVendors.isEmpty) return false;
        final allowed = config.codFeeApplicableVendors
            .map((e) => e.trim().toLowerCase())
            .toSet();
        return vendorIds
            .map((e) => e.trim().toLowerCase())
            .any(allowed.contains);
      case 'categories':
        if (config.codFeeApplicableCategories.isEmpty) return false;
        final allowed = config.codFeeApplicableCategories
            .map((e) => e.trim().toLowerCase())
            .toSet();
        return categories
            .map((e) => e.trim().toLowerCase())
            .any(allowed.contains);
      default:
        return true;
    }
  }
}
