import 'package:flutter/services.dart';

Future<void> playPlatformAlert(String soundType, {double volume = 1.0}) async {
  try {
    switch (soundType) {
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
