import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/loading/category_loader.dart';
import 'package:quickgrocery/core/loading/loading_assets.dart';
import 'package:quickgrocery/core/loading/loading_service.dart';
import 'package:quickgrocery/models/category_model.dart';

/// Orchestrates category-loader visual warm-up for splash / page waits.
abstract final class LoadingManager {
  LoadingManager._();

  static bool _booted = false;

  static Future<void> boot({
    BuildContext? context,
    Iterable<CategoryModel>? categories,
  }) async {
    if (categories != null && categories.isNotEmpty) {
      LoadingService.seedFromCategories(categories);
    }
    if (_booted) {
      if (context != null && context.mounted) {
        unawaited(LoadingService.precacheFirst(context));
        unawaited(LoadingService.precache(context));
      }
      return;
    }
    _booted = true;
    unawaited(LoadingAssets.warmUp());
    try {
      final prefs = await SharedPreferences.getInstance();
      await LoadingService.warmFromDisk(prefs);
    } catch (_) {}
    if (context != null && context.mounted) {
      unawaited(LoadingService.precacheFirst(context));
      unawaited(LoadingService.precache(context));
    }
  }

  static void seed(Iterable<CategoryModel> categories) {
    if (categories.isEmpty) return;
    LoadingService.seedFromCategories(categories);
  }

  static List<CategoryLoaderItem> get catalog => LoadingService.catalog;
}
