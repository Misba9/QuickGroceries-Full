/// Promotion type identifiers matching Cloud Functions `PROMOTION_TYPES`.
abstract final class PromotionTypes {
  static const flashSale = 'flash_sale';
  static const todaysDeal = 'todays_deal';
  static const featured = 'featured';
  static const bestSeller = 'best_seller';
  static const recommended = 'recommended';
  static const trending = 'trending';
  static const newArrival = 'new_arrival';
  static const limitedTime = 'limited_time';
  static const discountBadge = 'discount_badge';
  static const bogo = 'bogo';
  static const comboOffer = 'combo_offer';

  static const all = <String>[
    flashSale,
    todaysDeal,
    featured,
    bestSeller,
    recommended,
    trending,
    newArrival,
    limitedTime,
    discountBadge,
    bogo,
    comboOffer,
  ];

  static String label(String type) {
    switch (type) {
      case flashSale:
        return 'Flash Sale';
      case todaysDeal:
        return "Today's Deal";
      case featured:
        return 'Featured';
      case bestSeller:
        return 'Best Seller';
      case recommended:
        return 'Recommended';
      case trending:
        return 'Trending';
      case newArrival:
        return 'New Arrival';
      case limitedTime:
        return 'Limited Time Offer';
      case discountBadge:
        return 'Discount Badge';
      case bogo:
        return 'Buy One Get One';
      case comboOffer:
        return 'Combo Offer';
      default:
        return type;
    }
  }
}

class ProductPromotionModel {
  const ProductPromotionModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.vendorId,
    required this.vendorName,
    required this.promotionType,
    required this.enabled,
    this.salePrice,
    this.discountPercent,
    this.startDate,
    this.endDate,
    this.badge = '',
    this.bannerLabel = '',
    this.priority = 0,
    this.maxPurchase = 0,
    this.stockLimit = 0,
    this.pinToTop = false,
    this.visible = true,
    this.locked = true,
    this.expired = false,
    this.source = 'admin',
    this.createdBy = '',
    this.updatedBy = '',
    this.reason = '',
  });

  final String id;
  final String productId;
  final String productName;
  final String vendorId;
  final String vendorName;
  final String promotionType;
  final bool enabled;
  final double? salePrice;
  final double? discountPercent;
  final DateTime? startDate;
  final DateTime? endDate;
  final String badge;
  final String bannerLabel;
  final int priority;
  final int maxPurchase;
  final int stockLimit;
  final bool pinToTop;
  final bool visible;
  final bool locked;
  final bool expired;
  final String source;
  final String createdBy;
  final String updatedBy;
  final String reason;

  factory ProductPromotionModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      // Firestore Timestamp
      try {
        return (v as dynamic).toDate() as DateTime?;
      } catch (_) {
        return null;
      }
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return ProductPromotionModel(
      id: id,
      productId: data['productId']?.toString() ?? '',
      productName: data['productName']?.toString() ?? '',
      vendorId: data['vendorId']?.toString() ?? '',
      vendorName: data['vendorName']?.toString() ?? '',
      promotionType: data['promotionType']?.toString() ?? '',
      enabled: data['enabled'] == true,
      salePrice: asDouble(data['salePrice']),
      discountPercent: asDouble(data['discountPercent']),
      startDate: parseDate(data['startDate']),
      endDate: parseDate(data['endDate']),
      badge: data['badge']?.toString() ?? '',
      bannerLabel: data['bannerLabel']?.toString() ?? '',
      priority: asInt(data['priority']),
      maxPurchase: asInt(data['maxPurchase']),
      stockLimit: asInt(data['stockLimit']),
      pinToTop: data['pinToTop'] == true,
      visible: data['visible'] != false,
      locked: data['locked'] == true,
      expired: data['expired'] == true,
      source: data['source']?.toString() ?? 'admin',
      createdBy: data['createdBy']?.toString() ?? '',
      updatedBy: data['updatedBy']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
    );
  }

  String get typeLabel => PromotionTypes.label(promotionType);
}
