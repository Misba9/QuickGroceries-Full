import 'package:shared_preferences/shared_preferences.dart';

/// Throttles update checks (default once / 6 hours). Force updates bypass.
class UpdatePreferences {
  UpdatePreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _kLastCheckMs = 'app_update_last_check_ms';
  static const _kFlexibleReady = 'app_update_flexible_ready';

  static Future<UpdatePreferences> create() async {
    return UpdatePreferences(await SharedPreferences.getInstance());
  }

  DateTime? get lastCheckAt {
    final ms = _prefs.getInt(_kLastCheckMs);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool shouldCheck({
    required Duration throttle,
    required bool forceBypass,
  }) {
    if (forceBypass) return true;
    final last = lastCheckAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= throttle;
  }

  Future<void> markChecked() async {
    await _prefs.setInt(_kLastCheckMs, DateTime.now().millisecondsSinceEpoch);
  }

  bool get flexibleUpdateReady => _prefs.getBool(_kFlexibleReady) ?? false;

  Future<void> setFlexibleUpdateReady(bool ready) async {
    await _prefs.setBool(_kFlexibleReady, ready);
  }

  /// Test helper.
  Future<void> clear() async {
    await _prefs.remove(_kLastCheckMs);
    await _prefs.remove(_kFlexibleReady);
  }
}
