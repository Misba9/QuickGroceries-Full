import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/loading/loading_categories.dart';
import 'package:quickgrocery/core/loading/loading_random.dart';

/// Snapshot of the “alive” loader: category + message + emoji.
@immutable
class LoadingMoment {
  const LoadingMoment({
    required this.category,
    required this.message,
    required this.emoji,
  });

  final LoadingCategory category;
  final String message;
  final String emoji;

  factory LoadingMoment.fresh([LoadingRandom? rng]) {
    final r = rng ?? loadingRandom;
    final category = r.nextCategory();
    return LoadingMoment(
      category: category,
      message: r.nextStatusLine(category: category),
      emoji: category.emoji,
    );
  }
}

/// Lightweight Riverpod state for overlays that need shared rotating copy.
class LoadingController extends Notifier<LoadingMoment> {
  LoadingRandom get _rng => loadingRandom;

  @override
  LoadingMoment build() => LoadingMoment.fresh(_rng);

  void tick() {
    final category = _rng.nextCategory();
    state = LoadingMoment(
      category: category,
      message: _rng.nextStatusLine(category: category),
      emoji: category.emoji,
    );
  }

  void withPool(List<String> messages) {
    final category = _rng.nextCategory();
    state = LoadingMoment(
      category: category,
      message: _rng.nextMessage(pool: messages),
      emoji: category.emoji,
    );
  }
}

final loadingMomentProvider =
    NotifierProvider<LoadingController, LoadingMoment>(LoadingController.new);

/// Minimum time a loader should stay visible to avoid flash (ms).
const kMinLoadingDisplayMs = 400;

/// Animation window for category/message switches.
const kLoadingSwitchDuration = Duration(milliseconds: 420);
