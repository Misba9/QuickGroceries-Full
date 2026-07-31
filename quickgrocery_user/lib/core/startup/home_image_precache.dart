import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/models/product.dart';

/// Warms the image cache for first-paint hero assets — prevents banner flicker.
///
/// Uses [CachedNetworkImageProvider] so decode lands in the same cache as
/// Home [CachedImage] widgets (not Flutter's separate [NetworkImage] cache).
///
/// Decodes run in small concurrent batches with event-loop yields so splash /
/// Home stay near 60 FPS. Never awaits a large parallel decode burst on the
/// UI isolate.
abstract final class HomeImagePrecache {
  HomeImagePrecache._();

  static const int _maxConcurrent = 2;
  static const int _firstWaveCount = 8;
  static const int _totalCap = 28;
  /// Matches typical banner/product decode targets on Home.
  static const int _memCacheWidth = 720;

  static Future<void> warm(
    BuildContext context,
    HomeBootstrapSnapshot snapshot,
  ) async {
    if (!context.mounted) return;

    final urls = <String>{};

    void addProductImages(List<ProductModel> products, {int take = 8}) {
      for (final p in products.take(take)) {
        final image = p.image.trim();
        if (image.isNotEmpty) urls.add(image);
      }
    }

    for (final b in snapshot.banners.take(4)) {
      if (b.image.trim().isNotEmpty) urls.add(b.image.trim());
      if (b.thumbnailUrl.trim().isNotEmpty) urls.add(b.thumbnailUrl.trim());
    }
    for (final c in snapshot.categories.take(10)) {
      if (c.image.trim().isNotEmpty) urls.add(c.image.trim());
    }
    addProductImages(snapshot.flashSale, take: 8);
    addProductImages(snapshot.trending, take: 8);
    addProductImages(snapshot.featured, take: 6);
    for (final o in snapshot.offers.take(4)) {
      if (o.thumbnailUrl.trim().isNotEmpty) urls.add(o.thumbnailUrl.trim());
      if (o.imageFallbackUrl.trim().isNotEmpty) {
        urls.add(o.imageFallbackUrl.trim());
      }
    }

    if (urls.isEmpty) return;

    final list = urls.take(_totalCap).toList(growable: false);
    AppStartupLog.milestone('Precaching images', 'count=${list.length}');

    // Defer until after the current frame so first paint is never blocked.
    await _waitForNextFrame();
    if (!context.mounted) return;

    final firstWave = list.take(_firstWaveCount).toList(growable: false);
    await _precacheBatched(context, firstWave);

    if (!context.mounted) return;
    unawaited(_precacheBatched(context, list.skip(_firstWaveCount).toList()));

    AppStartupLog.milestone('Images precached (first wave)');
  }

  static Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    // Also schedule a frame if the engine is idle.
    SchedulerBinding.instance.scheduleFrame();
    return completer.future;
  }

  static Future<void> _precacheBatched(
    BuildContext context,
    List<String> urls,
  ) async {
    if (urls.isEmpty) return;

    var index = 0;
    Future<void> worker() async {
      while (true) {
        final i = index++;
        if (i >= urls.length) return;
        if (!context.mounted) return;
        try {
          await precacheImage(
            CachedNetworkImageProvider(
              urls[i],
              maxWidth: _memCacheWidth,
            ),
            context,
          );
        } catch (_) {}
        // Yield via frame callback — no Future.delayed / Timer.
        final gate = Completer<void>();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!gate.isCompleted) gate.complete();
        });
        SchedulerBinding.instance.scheduleFrame();
        await gate.future;
      }
    }

    final n = _maxConcurrent.clamp(1, urls.length);
    await Future.wait<void>(
      List.generate(n, (_) => worker()),
      eagerError: false,
    );
  }
}
