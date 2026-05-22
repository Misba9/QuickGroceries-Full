import 'package:quickgrocery/view/app_content/models/app_content_defaults.dart';

/// Remote copy for homepage headings and delivery ETA — `app_content/main`.
class AppContentConfig {
  const AppContentConfig({
    this.trendingHeading = AppContentDefaults.trendingHeading,
    this.shopCategoryHeading = AppContentDefaults.shopCategoryHeading,
    this.flashDealHeading = AppContentDefaults.flashDealHeading,
    this.deliveryTimeText = AppContentDefaults.deliveryTimeText,
    this.showTrendingCategories = true,
    this.showShopCategory = true,
    this.showFlashDeals = true,
  });

  static const defaults = AppContentConfig();

  final String trendingHeading;
  final String shopCategoryHeading;
  final String flashDealHeading;
  final String deliveryTimeText;
  final bool showTrendingCategories;
  final bool showShopCategory;
  final bool showFlashDeals;

  factory AppContentConfig.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    return AppContentConfig(
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
    );
  }

  static String _str(Object? value, String fallback) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return fallback;
    return s;
  }
}
