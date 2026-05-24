import 'package:quick_grocery_admin/view/operations/services/alert_sound_platform.dart';

/// Plays alert sounds per notification category (web + desktop/mobile).
class AdminAlertSoundService {
  const AdminAlertSoundService._();

  static DateTime? _lastPlayedAt;
  static String? _lastSoundType;
  static const _cooldown = Duration(seconds: 4);

  static Future<void> playForSoundType(
    String soundType, {
    required bool enabled,
    double volume = 1.0,
  }) async {
    if (!enabled) return;
    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        _lastSoundType == soundType &&
        now.difference(_lastPlayedAt!) < _cooldown) {
      return;
    }
    _lastPlayedAt = now;
    _lastSoundType = soundType;
    await playPlatformAlert(soundType, volume: volume);
  }

  static Future<void> preview(String soundType) =>
      playForSoundType(soundType, enabled: true);
}
