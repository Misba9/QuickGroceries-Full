import 'package:quick_grocery_admin/view/operations/services/alert_sound_platform.dart';

/// Plays alert sounds per notification category (web + desktop/mobile).
class AdminAlertSoundService {
  const AdminAlertSoundService._();

  static DateTime? _lastPlayedAt;
  static String? _lastSoundType;
  static const _cooldown = Duration(seconds: 4);
  static final Set<String> _playedOrderIds = {};
  static bool _unlocked = false;

  /// Call after first user gesture so web audio can autoplay.
  static Future<void> unlock() async {
    _unlocked = true;
    await unlockPlatformAudio();
  }

  static Future<void> playForSoundType(
    String soundType, {
    required bool enabled,
    double volume = 1.0,
    String? orderId,
  }) async {
    if (!enabled) return;
    if (orderId != null && orderId.isNotEmpty) {
      if (_playedOrderIds.contains(orderId)) return;
      _playedOrderIds.add(orderId);
    }
    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        _lastSoundType == soundType &&
        now.difference(_lastPlayedAt!) < _cooldown &&
        orderId == null) {
      return;
    }
    _lastPlayedAt = now;
    _lastSoundType = soundType;
    await playPlatformAlert(
      soundType,
      volume: volume,
      unlocked: _unlocked,
    );
  }

  static Future<void> preview(String soundType) async {
    _unlocked = true;
    await playForSoundType(soundType, enabled: true);
  }
}
