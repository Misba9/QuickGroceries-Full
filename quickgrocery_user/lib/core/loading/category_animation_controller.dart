import 'dart:math';

import 'package:quickgrocery/core/loading/category_loader.dart';
import 'package:quickgrocery/core/loading/loading_service.dart';

/// Launch-randomized sequential picker for one-by-one category loading.
///
/// Never repeats the previous item consecutively. Reshuffles when the deck
/// is exhausted so admin-added categories are included automatically.
class CategoryAnimationController {
  CategoryAnimationController({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<CategoryLoaderItem> _deck = <CategoryLoaderItem>[];
  String? _lastId;
  int _cursor = 0;

  void reshuffle([List<CategoryLoaderItem>? source]) {
    final pool = List<CategoryLoaderItem>.from(
      source ?? LoadingService.catalog,
    );
    if (pool.isEmpty) {
      pool.addAll(LoadingService.fallbackCatalog);
    }
    pool.shuffle(_random);
    _deck
      ..clear()
      ..addAll(pool);
    _cursor = 0;
  }

  CategoryLoaderItem next() {
    if (_deck.isEmpty) reshuffle();
    if (_deck.isEmpty) {
      return const CategoryLoaderItem(
        id: 'groceries',
        name: 'Groceries',
        emoji: '🛒',
      );
    }
    if (_deck.length == 1) {
      _lastId = _deck.first.id;
      return _deck.first;
    }

    for (var attempt = 0; attempt < _deck.length; attempt++) {
      final item = _deck[_cursor % _deck.length];
      _cursor++;
      if (_cursor >= _deck.length) {
        _cursor = 0;
        final again = List<CategoryLoaderItem>.from(_deck)..shuffle(_random);
        _deck
          ..clear()
          ..addAll(again);
      }
      if (item.id != _lastId) {
        _lastId = item.id;
        return item;
      }
    }
    final fallback = _deck[_random.nextInt(_deck.length)];
    _lastId = fallback.id;
    return fallback;
  }

  /// @deprecated Wheel API — returns a sequential sample for compatibility.
  List<CategoryLoaderItem> buildDeck({int? slotCount}) {
    reshuffle();
    final n = (slotCount ?? 10).clamp(1, 12);
    return List.generate(n, (_) => next());
  }
}
