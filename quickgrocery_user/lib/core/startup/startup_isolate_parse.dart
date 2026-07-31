import 'dart:convert';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/models/product.dart';

/// Off-UI-thread parsing helpers for startup / home rails.
///
/// Firestore [Timestamp] / nested maps are sanitized on the main isolate
/// (cheap), then [jsonDecode] + model factories run in [Isolate.run] /
/// [compute] so the UI thread stays free for 60 FPS frames.
abstract final class StartupIsolateParse {
  StartupIsolateParse._();

  /// Prefer isolate once payload is large enough to matter; tiny lists stay
  /// sync to avoid spawn overhead on the critical path.
  static const int isolateDocThreshold = 6;

  /// Convert Firestore-only types into isolate-safe primitives.
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      out[key] = _sanitizeValue(value);
    });
    return out;
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value == null ||
        value is bool ||
        value is num ||
        value is String) {
      return value;
    }
    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    if (value is GeoPoint) {
      return {'lat': value.latitude, 'lng': value.longitude};
    }
    if (value is DocumentReference) {
      return value.path;
    }
    if (value is Map) {
      return sanitizeMap(Map<String, dynamic>.from(value));
    }
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList(growable: false);
    }
    // Drop unsendable SDK types rather than crashing the isolate.
    return value.toString();
  }

  static List<Map<String, dynamic>> docsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return snap.docs
        .map(
          (d) => <String, dynamic>{
            'id': d.id,
            'data': sanitizeMap(d.data()),
          },
        )
        .toList(growable: false);
  }

  // ── Banner ──────────────────────────────────────────────────────────────

  static List<BannerModel> parseBannersSync(List<Map<String, dynamic>> docs) {
    final parsed = <BannerModel>[];
    for (final doc in docs) {
      final id = (doc['id'] ?? '').toString();
      final raw = doc['data'];
      if (id.isEmpty || raw is! Map) continue;
      try {
        parsed.add(
          BannerModel.fromFirestore(Map<String, dynamic>.from(raw), id),
        );
      } catch (_) {}
    }
    final items = parsed
        .where((b) => b.isActive)
        .where((b) => b.hasPromoMedia)
        .toList();
    items.sort((a, b) => a.priority.compareTo(b.priority));
    return items;
  }

  static Future<List<BannerModel>> parseBanners(
    List<Map<String, dynamic>> docs,
  ) async {
    if (docs.length < isolateDocThreshold) {
      return parseBannersSync(docs);
    }
    return Isolate.run(() => parseBannersSync(docs));
  }

  static Future<List<BannerModel>> parseBannersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return parseBanners(docsFromSnapshot(snap));
  }

  // ── Category ────────────────────────────────────────────────────────────

  static List<CategoryModel> parseCategoriesSync(
    List<Map<String, dynamic>> docs,
  ) {
    final items = <CategoryModel>[];
    for (final doc in docs) {
      final id = (doc['id'] ?? '').toString();
      final raw = doc['data'];
      if (id.isEmpty || raw is! Map) continue;
      try {
        final c = CategoryModel.fromFirestore(
          Map<String, dynamic>.from(raw),
          id,
        );
        if (c.isActive) items.add(c);
      } catch (_) {}
    }
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  static Future<List<CategoryModel>> parseCategories(
    List<Map<String, dynamic>> docs,
  ) async {
    if (docs.length < isolateDocThreshold) {
      return parseCategoriesSync(docs);
    }
    return Isolate.run(() => parseCategoriesSync(docs));
  }

  static Future<List<CategoryModel>> parseCategoriesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return parseCategories(docsFromSnapshot(snap));
  }

  // ── Product ─────────────────────────────────────────────────────────────

  static List<ProductModel> parseProductsSync(
    List<Map<String, dynamic>> docs, {
    bool onlyAvailable = false,
  }) {
    final out = <ProductModel>[];
    for (final doc in docs) {
      final id = (doc['id'] ?? '').toString();
      final raw = doc['data'];
      if (id.isEmpty || raw is! Map) continue;
      try {
        final p = ProductModel.fromFirestore(
          Map<String, dynamic>.from(raw),
          id,
        );
        if (!onlyAvailable || p.isAvailable) out.add(p);
      } catch (_) {}
    }
    return out;
  }

  static Future<List<ProductModel>> parseProducts(
    List<Map<String, dynamic>> docs, {
    bool onlyAvailable = false,
  }) async {
    if (docs.length < isolateDocThreshold) {
      return parseProductsSync(docs, onlyAvailable: onlyAvailable);
    }
    return Isolate.run(
      () => parseProductsSync(docs, onlyAvailable: onlyAvailable),
    );
  }

  static Future<List<ProductModel>> parseProductsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap, {
    bool onlyAvailable = false,
  }) {
    return parseProducts(
      docsFromSnapshot(snap),
      onlyAvailable: onlyAvailable,
    );
  }

  /// Untyped [QuerySnapshot] (legacy services) — sanitize in chunks with
  /// event-loop yields so a 300-doc dump cannot freeze the UI for one frame.
  static Future<List<ProductModel>> parseProductsFromUntypedSnapshot(
    QuerySnapshot<dynamic> snap, {
    bool onlyAvailable = false,
    int yieldEvery = 25,
  }) async {
    final docs = <Map<String, dynamic>>[];
    final raw = snap.docs;
    for (var i = 0; i < raw.length; i++) {
      final d = raw[i];
      final data = d.data();
      if (data is! Map) continue;
      docs.add({
        'id': d.id,
        'data': sanitizeMap(Map<String, dynamic>.from(data)),
      });
      if (yieldEvery > 0 && i > 0 && i % yieldEvery == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return parseProducts(docs, onlyAvailable: onlyAvailable);
  }

  // ── Offer banners ───────────────────────────────────────────────────────

  static List<OfferBannerModel> parseOffersSync(
    List<Map<String, dynamic>> docs,
  ) {
    final out = <OfferBannerModel>[];
    for (final doc in docs) {
      final id = (doc['id'] ?? '').toString();
      final raw = doc['data'];
      if (id.isEmpty || raw is! Map) continue;
      try {
        out.add(
          OfferBannerModel.fromFirestore(Map<String, dynamic>.from(raw), id),
        );
      } catch (_) {}
    }
    return out;
  }

  static Future<List<OfferBannerModel>> parseOffers(
    List<Map<String, dynamic>> docs,
  ) async {
    if (docs.length < isolateDocThreshold) {
      return parseOffersSync(docs);
    }
    return Isolate.run(() => parseOffersSync(docs));
  }

  // ── Disk JSON (HomeDataCache) ───────────────────────────────────────────

  /// Payload for [decodeHomeCachePayload] — plain strings only.
  static Map<String, String?> homeCachePayload({
    required String? banners,
    required String? categories,
    required String? featured,
    required String? trending,
    required String? flashSale,
    required String? offers,
  }) {
    return {
      'banners': banners,
      'categories': categories,
      'featured': featured,
      'trending': trending,
      'flashSale': flashSale,
      'offers': offers,
    };
  }

  /// Runs fully off the UI isolate — jsonDecode + model factories.
  static Map<String, List<dynamic>> decodeHomeCachePayload(
    Map<String, String?> payload,
  ) {
    List<Map<String, dynamic>> decodeDocs(String? raw) {
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final docs = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;
        // Timestamps already stored as ints in cache JSON.
        docs.add({'id': id, 'data': map});
      }
      return docs;
    }

    return {
      'banners': parseBannersSync(decodeDocs(payload['banners'])),
      'categories': parseCategoriesSync(decodeDocs(payload['categories'])),
      'featured': parseProductsSync(decodeDocs(payload['featured'])),
      'trending': parseProductsSync(decodeDocs(payload['trending'])),
      'flashSale': parseProductsSync(decodeDocs(payload['flashSale'])),
      'offers': parseOffersSync(decodeDocs(payload['offers'])),
    };
  }

  static Future<Map<String, List<dynamic>>> decodeHomeCache(
    Map<String, String?> payload,
  ) {
    // Always isolate — disk warm starts decode dozens of models.
    return Isolate.run(() => decodeHomeCachePayload(payload));
  }

  static String encodeJsonList(List<Map<String, dynamic>> items) {
    return jsonEncode(items);
  }

  static Future<String> encodeJsonListAsync(
    List<Map<String, dynamic>> items,
  ) {
    if (items.length < isolateDocThreshold) {
      return Future.value(encodeJsonList(items));
    }
    return Isolate.run(() => encodeJsonList(items));
  }
}
