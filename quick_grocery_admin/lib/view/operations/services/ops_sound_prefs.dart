import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local preference for optional admin alert sounds (web/desktop).
class OpsSoundPrefs extends ChangeNotifier {
  OpsSoundPrefs() {
    _load();
  }

  static const _key = 'admin_ops_sound_enabled';

  bool enabled = true;
  bool _loaded = false;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool(_key) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle() async {
    if (!_loaded) await _load();
    enabled = !enabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, enabled);
    notifyListeners();
  }
}
