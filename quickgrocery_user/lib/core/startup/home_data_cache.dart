import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/models/product.dart';

/// Disk cache for home feed data — enables instant paint on warm starts.
abstract final class HomeDataCache {
  static const _bannersKey = 'bootstrap_home_banners_v1';
  static const _categoriesKey = 'bootstrap_home_categories_v1';
  static const _featuredKey = 'bootstrap_home_featured_v1';
  static const _offersKey = 'bootstrap_home_offers_v1';
  static const _updatedAtKey = 'bootstrap_home_updated_at_v1';

  static Future<HomeBootstrapSnapshot> read(SharedPreferences prefs) async {
    try {
      final banners = _decodeList(
        prefs.getString(_bannersKey),
        (m, id) => BannerModel.fromFirestore(m, id),
      );
      final categories = _decodeList(
        prefs.getString(_categoriesKey),
        (m, id) => CategoryModel.fromFirestore(m, id),
      );
      final featured = _decodeList(
        prefs.getString(_featuredKey),
        (m, id) => ProductModel.fromFirestore(m, id),
      );
      final offers = _decodeList(
        prefs.getString(_offersKey),
        (m, id) => OfferBannerModel.fromFirestore(m, id),
      );
      if (banners.isEmpty &&
          categories.isEmpty &&
          featured.isEmpty &&
          offers.isEmpty) {
        return const HomeBootstrapSnapshot();
      }
      return HomeBootstrapSnapshot(
        banners: banners,
        categories: categories,
        featured: featured,
        offers: offers,
        loadedFromDisk: true,
      );
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
    try {
      await prefs.setString(
        _bannersKey,
        jsonEncode(_encodeList(snapshot.banners.map((b) => b.toJson()).toList())),
      );
      await prefs.setString(
        _categoriesKey,
        jsonEncode(
          _encodeList(snapshot.categories.map((c) => c.toJson()).toList()),
        ),
      );
      await prefs.setString(
        _featuredKey,
        jsonEncode(
          _encodeList(snapshot.featured.map((p) => p.toJson()).toList()),
        ),
      );
      await prefs.setString(
        _offersKey,
        jsonEncode(_encodeList(snapshot.offers.map(_offerToJson).toList())),
      );
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

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic> data, String id) parse,
  ) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final out = <T>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final id = (map['id'] ?? '').toString();
      if (id.isEmpty) continue;
      out.add(parse(_decodeTimestamps(map), id));
    }
    return out;
  }

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

  static Map<String, dynamic> _decodeTimestamps(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is int && _looksLikeEpoch(key)) {
        return MapEntry(key, Timestamp.fromMillisecondsSinceEpoch(value));
      }
      return MapEntry(key, value);
    });
  }

  static bool _looksLikeEpoch(String key) {
    final k = key.toLowerCase();
    return k.contains('at') || k.contains('date') || k.contains('time');
  }
}
