import 'package:cloud_firestore/cloud_firestore.dart';

/// Marketing & visibility flags for a product document.
class ProductSettings {
  const ProductSettings({
    this.isActive = true,
    this.isFlashSale = false,
    this.isTodaysBest = false,
    this.isMostSelling = false,
    this.isTrending = false,
    this.isRecommended = false,
    this.isFeatured = false,
    this.isPremium = false,
    this.isNewArrival = false,
    this.isLimitedStock = false,
    this.isOrganic = false,
    this.isFastSelling = false,
    this.isSeasonal = false,
    this.autoMostSelling = false,
    this.autoTrending = false,
    this.autoLimitedStock = false,
    this.autoNewArrival = false,
    this.flashSaleStart,
    this.flashSaleEnd,
    this.flashSaleStockLimit = 0,
    this.adminFeaturedApproved = true,
    this.adminSettingsLocked = false,
  });

  final bool isActive;
  final bool isFlashSale;
  final bool isTodaysBest;
  final bool isMostSelling;
  final bool isTrending;
  final bool isRecommended;
  final bool isFeatured;
  final bool isPremium;
  final bool isNewArrival;
  final bool isLimitedStock;
  final bool isOrganic;
  final bool isFastSelling;
  final bool isSeasonal;
  final bool autoMostSelling;
  final bool autoTrending;
  final bool autoLimitedStock;
  final bool autoNewArrival;
  final DateTime? flashSaleStart;
  final DateTime? flashSaleEnd;
  final int flashSaleStockLimit;
  final bool adminFeaturedApproved;
  final bool adminSettingsLocked;

  factory ProductSettings.fromMap(Map<String, dynamic> data) {
    return ProductSettings(
      isActive: _bool(data, 'isActive', alt: 'is_active', fallback: true),
      isFlashSale: _bool(data, 'is_flash_sale'),
      isTodaysBest: _bool(data, 'is_todays_best'),
      isMostSelling: _bool(data, 'is_most_selling', alt: 'most_sold'),
      isTrending: _bool(data, 'isTrending', alt: 'is_trending'),
      isRecommended: _bool(data, 'is_recommended'),
      isFeatured: _bool(data, 'isFeatured', alt: 'is_featured'),
      isPremium: _bool(data, 'premium_badge', alt: 'is_premium'),
      isNewArrival: _bool(data, 'is_new_arrival'),
      isLimitedStock: _bool(data, 'limited_stock', alt: 'is_limited_stock'),
      isOrganic: _bool(data, 'organic_product', alt: 'is_organic'),
      isFastSelling: _bool(data, 'fast_selling', alt: 'is_fast_selling'),
      isSeasonal: _bool(data, 'seasonal_product', alt: 'is_seasonal'),
      autoMostSelling: _bool(data, 'auto_most_selling'),
      autoTrending: _bool(data, 'auto_trending'),
      autoLimitedStock: _bool(data, 'auto_limited_stock'),
      autoNewArrival: _bool(data, 'auto_new_arrival'),
      flashSaleStart: _date(data['flash_sale_start']),
      flashSaleEnd: _date(data['flash_sale_end']),
      flashSaleStockLimit: (data['flash_sale_stock_limit'] as num?)?.toInt() ?? 0,
      adminFeaturedApproved: data['admin_featured_approved'] != false,
      adminSettingsLocked: data['admin_settings_locked'] == true,
    );
  }

  ProductSettings copyWith({
    bool? isActive,
    bool? isFlashSale,
    bool? isTodaysBest,
    bool? isMostSelling,
    bool? isTrending,
    bool? isRecommended,
    bool? isFeatured,
    bool? isPremium,
    bool? isNewArrival,
    bool? isLimitedStock,
    bool? isOrganic,
    bool? isFastSelling,
    bool? isSeasonal,
    bool? autoMostSelling,
    bool? autoTrending,
    bool? autoLimitedStock,
    bool? autoNewArrival,
    DateTime? flashSaleStart,
    DateTime? flashSaleEnd,
    int? flashSaleStockLimit,
    bool? adminFeaturedApproved,
    bool? adminSettingsLocked,
  }) {
    return ProductSettings(
      isActive: isActive ?? this.isActive,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      isTodaysBest: isTodaysBest ?? this.isTodaysBest,
      isMostSelling: isMostSelling ?? this.isMostSelling,
      isTrending: isTrending ?? this.isTrending,
      isRecommended: isRecommended ?? this.isRecommended,
      isFeatured: isFeatured ?? this.isFeatured,
      isPremium: isPremium ?? this.isPremium,
      isNewArrival: isNewArrival ?? this.isNewArrival,
      isLimitedStock: isLimitedStock ?? this.isLimitedStock,
      isOrganic: isOrganic ?? this.isOrganic,
      isFastSelling: isFastSelling ?? this.isFastSelling,
      isSeasonal: isSeasonal ?? this.isSeasonal,
      autoMostSelling: autoMostSelling ?? this.autoMostSelling,
      autoTrending: autoTrending ?? this.autoTrending,
      autoLimitedStock: autoLimitedStock ?? this.autoLimitedStock,
      autoNewArrival: autoNewArrival ?? this.autoNewArrival,
      flashSaleStart: flashSaleStart ?? this.flashSaleStart,
      flashSaleEnd: flashSaleEnd ?? this.flashSaleEnd,
      flashSaleStockLimit: flashSaleStockLimit ?? this.flashSaleStockLimit,
      adminFeaturedApproved:
          adminFeaturedApproved ?? this.adminFeaturedApproved,
      adminSettingsLocked: adminSettingsLocked ?? this.adminSettingsLocked,
    );
  }

  /// Dual-write map so User App + Admin stay in sync.
  Map<String, dynamic> toFirestorePatch({String? existingSpecialCat}) {
    final now = FieldValue.serverTimestamp();
    final patch = <String, dynamic>{
      'isActive': isActive,
      'is_active': isActive,
      'active': isActive,
      'updatedAt': now,
      'is_flash_sale': isFlashSale,
      'is_todays_best': isTodaysBest,
      'is_most_selling': isMostSelling,
      'most_sold': isMostSelling,
      'isTrending': isTrending,
      'is_trending': isTrending,
      'is_recommended': isRecommended,
      'isFeatured': isFeatured && adminFeaturedApproved,
      'is_featured': isFeatured && adminFeaturedApproved,
      'premium_badge': isPremium,
      'is_premium': isPremium,
      'is_new_arrival': isNewArrival,
      'limited_stock': isLimitedStock,
      'is_limited_stock': isLimitedStock,
      'organic_product': isOrganic,
      'is_organic': isOrganic,
      'fast_selling': isFastSelling,
      'is_fast_selling': isFastSelling,
      'seasonal_product': isSeasonal,
      'is_seasonal': isSeasonal,
      'auto_most_selling': autoMostSelling,
      'auto_trending': autoTrending,
      'auto_limited_stock': autoLimitedStock,
      'auto_new_arrival': autoNewArrival,
      'flash_sale_stock_limit': flashSaleStockLimit,
      'lastEdited': now,
      'settings_updated_at': now,
    };

    if (isTodaysBest) {
      patch['special_cat'] = "Today's snacks deals";
    } else if (existingSpecialCat == "Today's snacks deals") {
      patch['special_cat'] = '';
    }

    if (flashSaleStart != null) {
      patch['flash_sale_start'] = Timestamp.fromDate(flashSaleStart!);
    }
    if (flashSaleEnd != null) {
      patch['flash_sale_end'] = Timestamp.fromDate(flashSaleEnd!);
    }

    if (isFlashSale && flashSaleStart == null && flashSaleEnd == null) {
      final start = DateTime.now();
      patch['flash_sale_start'] = Timestamp.fromDate(start);
      patch['flash_sale_end'] =
          Timestamp.fromDate(start.add(const Duration(hours: 24)));
    }

    return patch;
  }

  static bool _bool(
    Map<String, dynamic> data,
    String key, {
    String? alt,
    String? alt2,
    bool fallback = false,
  }) {
    if (data.containsKey(key)) return data[key] == true;
    if (alt != null && data.containsKey(alt)) return data[alt] == true;
    if (alt2 != null && data.containsKey(alt2)) return data[alt2] == true;
    return fallback;
  }

  static DateTime? _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
