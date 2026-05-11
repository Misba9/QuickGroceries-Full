import 'package:quickgrocery/view/cart/domain/cart_models.dart';

/// Central place for **user-visible** delivery / pricing copy and flags.
///
/// Today this reads from [PricingConfig] (Firestore-backed, realtime).
/// Future extensions can compose multiple strategies without touching every UI:
///
/// - **Distance-based delivery**: add `DeliveryDistanceContext` and branch in
///   [userSummary] when `config.distanceKm != null`.
/// - **Surge pricing**: already surfaced via [PricingConfig.surgeActive]; extend
///   [signature] + banners when surge rules move to a dedicated sub-document.
/// - **Festival free delivery**: read optional `festivalFreeDeliveryUntil` from
///   Firestore into [PricingConfig] and prefer festival copy when active.
/// - **Zone-based pricing**: merge zone charge in the cart/checkout layer
///   (already partially via pin); keep policy strings aware of `zoneLabel`.
///
/// Keep this file **pure** (no `BuildContext`, no Firebase) so it is easy to
/// unit-test and reuse from widgets, listeners, and tests.
class DeliveryPricingPolicy {
  DeliveryPricingPolicy._();

  /// Compact string for deduping stream emissions / snackbars.
  static String signature(PricingConfig c) =>
      '${c.platformFee}|${c.handlingCharge}|${c.isFreeDeliveryEnabled}|'
      '${c.freeDeliveryThreshold}|${c.defaultDeliveryCharge}|'
      '${c.standardDeliveryCharge}|${c.isDeliveryChargesEnabled}|'
      '${c.surgeActive}|${c.surgeMultiplier}';

  static String homePromoLine(PricingConfig c) {
    if (!c.isDeliveryChargesEnabled) {
      return '🚚 Delivery charges are OFF right now';
    }
    if (c.isFreeDeliveryEnabled) {
      return '🚚 Free delivery above ₹${c.freeDeliveryThreshold}';
    }
    return '🚚 Delivery from ₹${c.standardDeliveryCharge}';
  }

  static String offersLine(PricingConfig c) {
    if (!c.isDeliveryChargesEnabled) {
      return 'Delivery charges are currently waived.';
    }
    if (c.isFreeDeliveryEnabled) {
      return 'Free delivery on orders above ₹${c.freeDeliveryThreshold}';
    }
    return 'Delivery fee ₹${c.standardDeliveryCharge} applies at checkout';
  }

  static String productEligibilityLine(PricingConfig c) {
    if (!c.isDeliveryChargesEnabled) {
      return 'No delivery fee on your order today';
    }
    if (c.isFreeDeliveryEnabled) {
      return 'Eligible for free delivery above ₹${c.freeDeliveryThreshold}';
    }
    return 'Delivery fee ₹${c.standardDeliveryCharge} may apply at checkout';
  }

  static String startupFooterLine(PricingConfig c) {
    if (!c.isDeliveryChargesEnabled) {
      return '🎁 No delivery fee — enjoy savings on every order';
    }
    if (c.isFreeDeliveryEnabled) {
      return '🚚 Free delivery on orders above ₹${c.freeDeliveryThreshold}';
    }
    return '🚚 Standard delivery ₹${c.standardDeliveryCharge} below threshold';
  }

  static String notificationLiveLine(PricingConfig c) {
    return 'Live · ${homePromoLine(c)}';
  }

  static String snackbarOnRemoteChange(PricingConfig c) {
    if (!c.isDeliveryChargesEnabled) {
      return 'Delivery updated: charges disabled for now';
    }
    if (c.isFreeDeliveryEnabled) {
      return 'Delivery updated: free delivery above ₹${c.freeDeliveryThreshold}';
    }
    return 'Delivery updated: fee ₹${c.standardDeliveryCharge} below threshold';
  }
}
