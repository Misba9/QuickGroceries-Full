import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/startup_isolate_parse.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/models/product.dart';

/// Disk cache for home feed data — enables instant paint on warm starts.
abstract final class HomeDataCache {
  static const _bannersKey = 'bootstrap_home_banners_v1';
  static const _categoriesKey = 'bootstrap_home_categories_v1';
  static const _featuredKey = 'bootstrap_home_featured_v1';
  static const _trendingKey = 'bootstrap_home_trending_v1';
  static const _flashSaleKey = 'bootstrap_home_flash_v1';
  static const _offersKey = 'bootstrap_home_offers_v1';
  static const _updatedAtKey = 'bootstrap_home_updated_at_v1';

  /// In-memory hit so LoadingService + bootstrap do not double-decode JSON.
  static HomeBootstrapSnapshot? _memory;

  static Future<HomeBootstrapSnapshot> read(SharedPreferences prefs) async {
    final cached = _memory;
    if (cached != null && cached.hasContent) return cached;

    try {
      final payload = StartupIsolateParse.homeCachePayload(
        banners: prefs.getString(_bannersKey),
        categories: prefs.getString(_categoriesKey),
        featured: prefs.getString(_featuredKey),
        trending: prefs.getString(_trendingKey),
        flashSale: prefs.getString(_flashSaleKey),
        offers: prefs.getString(_offersKey),
      );

      final empty = payload.values.every((v) => v == null || v.isEmpty);
      if (empty) return const HomeBootstrapSnapshot();

      // jsonDecode + banner/category/product/offer factories off UI isolate.
      final decoded = await StartupIsolateParse.decodeHomeCache(payload);

      final snapshot = HomeBootstrapSnapshot(
        banners: decoded['banners']!.cast<BannerModel>(),
        categories: decoded['categories']!.cast<CategoryModel>(),
        featured: decoded['featured']!.cast<ProductModel>(),
        trending: decoded['trending']!.cast<ProductModel>(),
        flashSale: decoded['flashSale']!.cast<ProductModel>(),
        offers: decoded['offers']!.cast<OfferBannerModel>(),
        loadedFromDisk: true,
      );
      if (snapshot.hasContent) _memory = snapshot;
      return snapshot;
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeDataCache] read failed: $e');
      return const HomeBootstrapSnapshot();
    }
  }

  static Future<void> write(
    SharedPreferences prefs,
    HomeBootstrapSnapshot snapshot,
  ) async {
    if (!snapshot.hasContent) return;
    _memory = snapshot;
    try {
      final bannersJson = await StartupIsolateParse.encodeJsonListAsync(
        _encodeList(snapshot.banners.map((b) => b.toJson()).toList()),
      );
      final categoriesJson = await StartupIsolateParse.encodeJsonListAsync(
        _encodeList(snapshot.categories.map((c) => c.toJson()).toList()),
      );
      final featuredJson = await StartupIsolateParse.encodeJsonListAsync(
        _encodeList(snapshot.featured.map((p) => p.toJson()).toList()),
      );
      final trendingJson = await StartupIsolateParse.encodeJsonListAsync(
        _encodeList(snapshot.trending.map((p) => p.toJson()).toList()),
      );
      final flashJson = await StartupIsolateParse.encodeJsonListAsync(
        _encodeList(snapshot.flashSale.map((p) => p.toJson()).toList()),
      );
      final offersJson = await StartupIsolateParse.encodeJsonListAsync(
        _encodeList(snapshot.offers.map(_offerToJson).toList()),
      );

      await prefs.setString(_bannersKey, bannersJson);
      await prefs.setString(_categoriesKey, categoriesJson);
      await prefs.setString(_featuredKey, featuredJson);
      await prefs.setString(_trendingKey, trendingJson);
      await prefs.setString(_flashSaleKey, flashJson);
      await prefs.setString(_offersKey, offersJson);
      await prefs.setInt(
        _updatedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeDataCache] write failed: $e');
    }
  }

  static Map<String, dynamic> _offerToJson(OfferBannerModel o) => {
        'id': o.id,
        'title': o.title,
        'subtitle': o.subtitle,
        'description': o.description,
        'videoUrl': o.videoUrl,
        'thumbnailUrl': o.thumbnailUrl,
        'imageFallbackUrl': o.imageFallbackUrl,
        'ctaText': o.ctaText,
        'redirectType': o.redirectType,
        'redirectId': o.redirectId,
        if (o.startsAt != null)
          'startsAt': o.startsAt!.millisecondsSinceEpoch,
        if (o.endsAt != null) 'endsAt': o.endsAt!.millisecondsSinceEpoch,
        'priority': o.priority,
        'isActive': o.isActive,
        'showOnHomepage': o.showOnHomepage,
        'showInHomeExplore': o.showInHomeExplore,
        'showOnOffersPage': o.showOnOffersPage,
        'showAsPopup': o.showAsPopup,
        'showInStories': o.showInStories,
        'fromBannersCollection': o.fromBannersCollection,
      };

  static List<Map<String, dynamic>> _encodeList(
    List<Map<String, dynamic>> items,
  ) {
    return items.map(_encodeTimestamps).toList();
  }

  static Map<String, dynamic> _encodeTimestamps(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      }
      if (value is DateTime) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      }
      return MapEntry(key, value);
    });
  }

  static Future<void> clearOnLogout(SharedPreferences prefs) async {
    _memory = null;
    await prefs.remove(_bannersKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_featuredKey);
    await prefs.remove(_trendingKey);
    await prefs.remove(_flashSaleKey);
    await prefs.remove(_offersKey);
    await prefs.remove(_updatedAtKey);
  }
}
