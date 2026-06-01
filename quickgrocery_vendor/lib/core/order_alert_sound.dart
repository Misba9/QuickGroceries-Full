import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Short alert for new / updated orders (mobile + desktop).
class OrderAlertSound {
  OrderAlertSound._();

  static final AudioPlayer _player = AudioPlayer();
  static DateTime? _lastPlayed;
  static const _cooldown = Duration(seconds: 3);

  static Future<void> playNewOrder() async {
    final now = DateTime.now();
    if (_lastPlayed != null && now.difference(_lastPlayed!) < _cooldown) {
      return;
    }
    _lastPlayed = now;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/new_order.mp3'));
      if (kDebugMode) {
        debugPrint('[VendorNotify] sound played new_order.mp3');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderAlertSound] $e');
    }
  }
}
