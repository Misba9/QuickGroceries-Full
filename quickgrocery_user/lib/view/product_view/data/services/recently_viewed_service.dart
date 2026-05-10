import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's recently-viewed product ids in [SharedPreferences].
///
/// Capped to [maxItems] entries — newest first, no duplicates.
/// All I/O is async; callers should treat reads as awaitable.
class RecentlyViewedService {
  RecentlyViewedService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _key = 'recently_viewed_product_ids';
  static const int maxItems = 12;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<String>> read() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_key) ?? const [];
  }

  Future<List<String>> add(String productId) async {
    if (productId.isEmpty) return read();
    final prefs = await _getPrefs();
    final current = prefs.getStringList(_key) ?? <String>[];
    final updated = <String>[
      productId,
      ...current.where((id) => id != productId),
    ];
    if (updated.length > maxItems) {
      updated.removeRange(maxItems, updated.length);
    }
    await prefs.setStringList(_key, updated);
    return updated;
  }

  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove(_key);
  }
}
