import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quick_grocery_admin/model/app_content_defaults.dart';

/// Firestore `app_content/main` — synced live to the customer app.
class AppContentModel {
  const AppContentModel({
    this.trendingHeading = AppContentDefaults.trendingHeading,
    this.shopCategoryHeading = AppContentDefaults.shopCategoryHeading,
    this.flashDealHeading = AppContentDefaults.flashDealHeading,
    this.deliveryTimeText = AppContentDefaults.deliveryTimeText,
    this.showTrendingCategories = true,
    this.showShopCategory = true,
    this.showFlashDeals = true,
    this.updatedAt,
  });

  static const defaults = AppContentModel();

  final String trendingHeading;
  final String shopCategoryHeading;
  final String flashDealHeading;
  final String deliveryTimeText;
  final bool showTrendingCategories;
  final bool showShopCategory;
  final bool showFlashDeals;
  final DateTime? updatedAt;

  factory AppContentModel.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    DateTime? updated;
    final ts = raw['updated_at'];
    if (ts is Timestamp) updated = ts.toDate();

    return AppContentModel(
      trendingHeading: _str(raw['trending_heading'], defaults.trendingHeading),
      shopCategoryHeading:
          _str(raw['shop_category_heading'], defaults.shopCategoryHeading),
      flashDealHeading:
          _str(raw['flash_deal_heading'], defaults.flashDealHeading),
      deliveryTimeText:
          _str(raw['delivery_time_text'], defaults.deliveryTimeText),
      showTrendingCategories:
          raw['show_trending_categories'] as bool? ?? true,
      showShopCategory: raw['show_shop_category'] as bool? ?? true,
      showFlashDeals: raw['show_flash_deals'] as bool? ?? true,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'home_greeting': FieldValue.delete(),
        'trending_heading': trendingHeading.trim(),
        'shop_category_heading': shopCategoryHeading.trim(),
        'flash_deal_heading': flashDealHeading.trim(),
        'delivery_time_text': deliveryTimeText.trim(),
        'show_trending_categories': showTrendingCategories,
        'show_shop_category': showShopCategory,
        'show_flash_deals': showFlashDeals,
        'updated_at': FieldValue.serverTimestamp(),
      };

  AppContentModel copyWith({
    String? trendingHeading,
    String? shopCategoryHeading,
    String? flashDealHeading,
    String? deliveryTimeText,
    bool? showTrendingCategories,
    bool? showShopCategory,
    bool? showFlashDeals,
    DateTime? updatedAt,
  }) {
    return AppContentModel(
      trendingHeading: trendingHeading ?? this.trendingHeading,
      shopCategoryHeading: shopCategoryHeading ?? this.shopCategoryHeading,
      flashDealHeading: flashDealHeading ?? this.flashDealHeading,
      deliveryTimeText: deliveryTimeText ?? this.deliveryTimeText,
      showTrendingCategories:
          showTrendingCategories ?? this.showTrendingCategories,
      showShopCategory: showShopCategory ?? this.showShopCategory,
      showFlashDeals: showFlashDeals ?? this.showFlashDeals,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _str(Object? value, String fallback) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return fallback;
    return s;
  }
}
