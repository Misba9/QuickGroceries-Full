import 'package:flutter/services.dart';

Future<void> unlockPlatformAudio() async {}

Future<void> playPlatformAlert(
  String soundType, {
  double volume = 1.0,
  bool unlocked = false,
}) async {
  try {
    switch (soundType) {
      case 'orders':
        // Asset playback on desktop uses system sounds until audioplayers is added.
        await SystemSound.play(SystemSoundType.alert);
        break;
      case 'payments':
      case 'security':
      case 'vendors':
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
  } catch (_) {}
}
