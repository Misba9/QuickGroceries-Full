import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local preferences for admin alert sounds (mute + volume).
class OpsSoundPrefs extends ChangeNotifier {
  OpsSoundPrefs() {
    _load();
  }

  static const _enabledKey = 'admin_ops_sound_enabled';
  static const _volumeKey = 'admin_ops_sound_volume';

  bool enabled = true;
  double volume = 0.85;
  bool _loaded = false;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool(_enabledKey) ?? true;
    volume = p.getDouble(_volumeKey) ?? 0.85;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (!_loaded) await _load();
    enabled = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabledKey, enabled);
    notifyListeners();
  }

  Future<void> toggle() => setEnabled(!enabled);

  Future<void> setVolume(double v) async {
    if (!_loaded) await _load();
    volume = v.clamp(0.0, 1.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_volumeKey, volume);
    notifyListeners();
  }
}
