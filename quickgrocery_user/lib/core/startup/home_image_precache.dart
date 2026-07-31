import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_state.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';

/// Precache **only first-viewport** images after Home paints.
///
/// Remaining rails lazy-load via [CachedNetworkImage] as they scroll into view.
/// Concurrency 1 + frame yields — never burst-decode on startup.
abstract final class HomeImagePrecache {
  HomeImagePrecache._();

  static const int _maxConcurrent = 1;
  /// First banner + ~4 category chips + ~2 product thumbs.
  static const int _totalCap = 7;
  static const int _memCacheWidth = 360;

  static Future<void> warm(
    BuildContext context,
    HomeBootstrapSnapshot snapshot,
  ) async {
    if (!context.mounted) return;

    final urls = <String>{};

    for (final b in snapshot.banners.take(1)) {
      final u =
          b.image.trim().isNotEmpty ? b.image.trim() : b.thumbnailUrl.trim();
      if (u.isNotEmpty) urls.add(u);
    }
    for (final c in snapshot.categories.take(4)) {
      if (c.image.trim().isNotEmpty) urls.add(c.image.trim());
    }
    for (final p in snapshot.featured.take(2)) {
      if (p.image.trim().isNotEmpty) urls.add(p.image.trim());
    }

    if (urls.isEmpty) return;
    final list = urls.take(_totalCap).toList(growable: false);
    AppStartupLog.milestone('Precaching images', 'count=${list.length}');

    await _waitForNextFrame();
    if (!context.mounted) return;
    await _precacheBatched(context, list);
  }

  static Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
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
            CachedNetworkImageProvider(urls[i], maxWidth: _memCacheWidth),
            context,
          );
        } catch (_) {}
        final gate = Completer<void>();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!gate.isCompleted) gate.complete();
        });
        SchedulerBinding.instance.scheduleFrame();
        await gate.future;
      }
    }

    await Future.wait<void>(
      List.generate(_maxConcurrent.clamp(1, urls.length), (_) => worker()),
      eagerError: false,
    );
  }
}
