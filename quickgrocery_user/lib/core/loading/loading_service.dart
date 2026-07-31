import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/loading/category_loader.dart';
import 'package:quickgrocery/core/loading/loading_categories.dart';
import 'package:quickgrocery/core/startup/home_data_cache.dart';
import 'package:quickgrocery/models/category_model.dart';

/// Sources + precaches live category visuals for loaders.
///
/// Does not call category APIs — only reuses disk cache / bootstrap snapshot
/// and existing in-project grocery image assets as cold-start fallbacks.
abstract final class LoadingService {
  LoadingService._();

  static final List<CategoryLoaderItem> _catalog = <CategoryLoaderItem>[];
  static bool _warmed = false;

  /// Current catalog (live categories when seeded, else asset fallbacks).
  static List<CategoryLoaderItem> get catalog {
    if (_catalog.isNotEmpty) return List.unmodifiable(_catalog);
    return fallbackCatalog;
  }

  /// Local grocery images already shipped in the app (first-launch safety net).
  static const fallbackCatalog = <CategoryLoaderItem>[
    CategoryLoaderItem(
      id: 'asset_dairy',
      name: 'Dairy',
      assetPath: 'assets/images/dairy.png',
      emoji: '🥛',
    ),
    CategoryLoaderItem(
      id: 'asset_vegetables',
      name: 'Vegetables',
      assetPath: 'assets/images/vegitable.png',
      emoji: '🥬',
    ),
    CategoryLoaderItem(
      id: 'asset_fruits',
      name: 'Fruits',
      assetPath: 'assets/images/mango.png',
      emoji: '🍎',
    ),
    CategoryLoaderItem(
      id: 'asset_bakery',
      name: 'Bakery',
      assetPath: 'assets/images/aata.png',
      emoji: '🥖',
    ),
    CategoryLoaderItem(
      id: 'asset_snacks',
      name: 'Snacks',
      assetPath: 'assets/images/yipee.png',
      emoji: '🍪',
    ),
    CategoryLoaderItem(
      id: 'asset_drinks',
      name: 'Cold Drinks',
      assetPath: 'assets/images/cola.png',
      emoji: '🥤',
    ),
    CategoryLoaderItem(
      id: 'asset_masala',
      name: 'Masala',
      assetPath: 'assets/images/masala.png',
      emoji: '🧂',
    ),
    CategoryLoaderItem(
      id: 'asset_seafood',
      name: 'Seafood',
      assetPath: 'assets/images/fish.png',
      emoji: '🐟',
    ),
    CategoryLoaderItem(
      id: 'asset_tomato',
      name: 'Fresh Produce',
      assetPath: 'assets/images/tomato.png',
      emoji: '🍅',
    ),
    CategoryLoaderItem(
      id: 'asset_coffee',
      name: 'Beverages',
      assetPath: 'assets/images/coffw.png',
      emoji: '☕',
    ),
  ];

  /// Replace catalog from live [CategoryModel]s (admin-driven).
  /// Prefers categories that have real images; keeps others as glyph fallback.
  static void seedFromCategories(Iterable<CategoryModel> categories) {
    final withImage = <CategoryLoaderItem>[];
    final without = <CategoryLoaderItem>[];
    for (final c in categories) {
      if (!c.isActive) continue;
      final name = c.name.trim();
      if (name.isEmpty) continue;
      final url = c.image.trim();
      final item = CategoryLoaderItem(
        id: c.id.isNotEmpty ? c.id : name.toLowerCase(),
        name: name,
        imageUrl: url.isEmpty ? null : url,
        emoji: _emojiForName(name),
      );
      if (url.isNotEmpty) {
        withImage.add(item);
      } else {
        without.add(item);
      }
    }
    final next = withImage.isNotEmpty ? withImage : without;
    if (next.isEmpty) return;
    _catalog
      ..clear()
      ..addAll(next);
  }

  /// Best-effort disk seed — never blocks startup UI.
  static Future<void> warmFromDisk(SharedPreferences prefs) async {
    try {
      final snap = await HomeDataCache.read(prefs);
      if (snap.categories.isNotEmpty) {
        seedFromCategories(snap.categories);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LoadingService] warmFromDisk: $e');
    }
  }

  /// Precache the first category image ASAP (logo → category handoff).
  static Future<void> precacheFirst(BuildContext context) async {
    if (!context.mounted) return;
    final items = catalog;
    if (items.isEmpty) return;
    await _precacheItem(context, items.first);
  }

  /// Precache network + asset category images. Fire-and-forget.
  static Future<void> precache(BuildContext context) async {
    // Always warm the first image so logo→category has zero blank frames.
    await precacheFirst(context);
    if (_warmed) return;
    _warmed = true;
    final items = catalog;
    for (final item in items.skip(1).take(11)) {
      if (!context.mounted) return;
      await _precacheItem(context, item);
      // Yield to the next frame between decodes (no Timer / delayed).
      await _nextFrame();
    }
  }

  static Future<void> _nextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    SchedulerBinding.instance.scheduleFrame();
    return completer.future;
  }

  static Future<void> _precacheItem(
    BuildContext context,
    CategoryLoaderItem item,
  ) async {
    try {
      if (item.hasNetworkImage) {
        await precacheImage(
          CachedNetworkImageProvider(item.imageUrl!),
          context,
        );
      } else if (item.hasAsset) {
        await precacheImage(AssetImage(item.assetPath!), context);
      }
    } catch (_) {
      // Non-fatal.
    }
  }

  static String _emojiForName(String name) {
    final n = name.toLowerCase();
    for (final cat in LoadingCategories.all) {
      if (n.contains(cat.id) ||
          n.contains(cat.label.toLowerCase().split(' ').first)) {
        return cat.emoji;
      }
    }
    if (n.contains('milk') || n.contains('dairy')) return '🥛';
    if (n.contains('veg')) return '🥬';
    if (n.contains('fruit')) return '🍎';
    if (n.contains('bakery') || n.contains('bread')) return '🥖';
    if (n.contains('rice') || n.contains('atta') || n.contains('grain')) {
      return '🍚';
    }
    if (n.contains('snack')) return '🍪';
    if (n.contains('egg')) return '🥚';
    if (n.contains('drink') || n.contains('beverage') || n.contains('cola')) {
      return '🥤';
    }
    if (n.contains('pet')) return '🐶';
    if (n.contains('baby')) return '👶';
    if (n.contains('medicine') || n.contains('health') || n.contains('pharma')) {
      return '💊';
    }
    if (n.contains('beauty') || n.contains('personal')) return '🧴';
    if (n.contains('clean') || n.contains('household')) return '🧹';
    if (n.contains('stationery') || n.contains('office')) return '📎';
    if (n.contains('dry fruit') || n.contains('nut')) return '🥜';
    return '🛒';
  }
}
