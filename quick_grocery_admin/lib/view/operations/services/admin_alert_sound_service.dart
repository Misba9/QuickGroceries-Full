import 'package:flutter/services.dart';

/// Plays short system sounds per notification category (no asset files required).
class AdminAlertSoundService {
  const AdminAlertSoundService._();

  static Future<void> playForSoundType(
    String soundType, {
    required bool enabled,
  }) async {
    if (!enabled) return;
    try {
      switch (soundType) {
        case 'payments':
        case 'security':
          await SystemSound.play(SystemSoundType.alert);
          break;
        case 'stock':
          await SystemSound.play(SystemSoundType.alert);
          await Future<void>.delayed(const Duration(milliseconds: 120));
          await SystemSound.play(SystemSoundType.click);
          break;
        default:
          await SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {
      // Web/desktop may not support all system sounds.
    }
  }

  static Future<void> preview(String soundType) =>
      playForSoundType(soundType, enabled: true);
}
