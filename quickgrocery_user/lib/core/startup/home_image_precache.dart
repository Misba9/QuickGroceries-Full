import 'package:flutter/material.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';

/// Warms the image cache for first-paint hero assets — prevents banner flicker.
abstract final class HomeImagePrecache {
  HomeImagePrecache._();

  static Future<void> warm(
    BuildContext context,
    HomeBootstrapSnapshot snapshot,
  ) async {
    if (!context.mounted) return;

    final urls = <String>{};
    for (final b in snapshot.banners.take(4)) {
      if (b.image.trim().isNotEmpty) urls.add(b.image.trim());
      if (b.thumbnailUrl.trim().isNotEmpty) urls.add(b.thumbnailUrl.trim());
    }
    for (final c in snapshot.categories.take(10)) {
      if (c.image.trim().isNotEmpty) urls.add(c.image.trim());
    }
    for (final p in snapshot.featured.take(8)) {
      if (p.image.trim().isNotEmpty) urls.add(p.image.trim());
    }
    for (final o in snapshot.offers.take(4)) {
      if (o.thumbnailUrl.trim().isNotEmpty) urls.add(o.thumbnailUrl.trim());
      if (o.imageFallbackUrl.trim().isNotEmpty) {
        urls.add(o.imageFallbackUrl.trim());
      }
    }

    if (urls.isEmpty) return;

    AppStartupLog.milestone('Precaching images', 'count=${urls.length}');

    await Future.wait<void>(
      urls.take(16).map((url) async {
        try {
          await precacheImage(NetworkImage(url), context);
        } catch (_) {
          // Non-fatal — CachedImage will load on demand.
        }
      }),
      eagerError: false,
    );

    AppStartupLog.milestone('Images precached');
  }
}
