import 'dart:math';

import 'package:quickgrocery/core/loading/loading_categories.dart';
import 'package:quickgrocery/core/loading/loading_messages.dart';

/// Anti-repetition randomizer for category / message / emoji picks.
class LoadingRandom {
  LoadingRandom({Random? random}) : _random = random ?? Random();

  final Random _random;
  String? _lastCategoryId;
  String? _lastMessage;
  String? _lastEmoji;

  LoadingCategory nextCategory() {
    final pool = LoadingCategories.all;
    if (pool.length == 1) return pool.first;
    LoadingCategory pick;
    do {
      pick = pool[_random.nextInt(pool.length)];
    } while (pick.id == _lastCategoryId);
    _lastCategoryId = pick.id;
    return pick;
  }

  String nextMessage({List<String>? pool}) {
    final list = pool ?? LoadingMessages.friendly;
    if (list.isEmpty) return 'Just a moment...';
    if (list.length == 1) return list.first;
    String pick;
    do {
      pick = list[_random.nextInt(list.length)];
    } while (pick == _lastMessage);
    _lastMessage = pick;
    return pick;
  }

  String nextEmoji() {
    final pool = LoadingCategories.emojiPool;
    if (pool.length == 1) return pool.first;
    String pick;
    do {
      pick = pool[_random.nextInt(pool.length)];
    } while (pick == _lastEmoji);
    _lastEmoji = pick;
    return pick;
  }

  /// Category-aware status: prefer category message, else friendly pool.
  String nextStatusLine({LoadingCategory? category}) {
    if (_random.nextBool() && category != null) {
      final msg = category.loadingMessage;
      if (msg != _lastMessage) {
        _lastMessage = msg;
        return msg;
      }
    }
    return nextMessage();
  }

  int nextInt(int max) => _random.nextInt(max);
}

/// Shared singleton for splash / overlays (widgets can also create local ones).
final loadingRandom = LoadingRandom();
