import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.HTMLAudioElement? _orderAudio;

Future<void> unlockPlatformAudio() async {
  try {
    _orderAudio ??= web.HTMLAudioElement()
      ..src = 'assets/assets/sounds/new_order.wav'
      ..preload = 'auto';
    _orderAudio!.volume = 0.001;
    await _orderAudio!.play().toDart;
    _orderAudio!.pause();
    _orderAudio!.currentTime = 0;
    _orderAudio!.volume = 1;
  } catch (_) {
    try {
      final ctx = web.AudioContext();
      if (ctx.state == 'suspended') {
        await ctx.resume().toDart;
      }
      ctx.close();
    } catch (_) {}
  }
}

Future<void> playPlatformAlert(
  String soundType, {
  double volume = 1.0,
  bool unlocked = false,
}) async {
  if (soundType == 'orders' || soundType.isEmpty) {
    final played = await _playOrderAsset(volume);
    if (played) return;
  }
  await _playBeep(soundType, volume);
}

Future<bool> _playOrderAsset(double volume) async {
  try {
    _orderAudio ??= web.HTMLAudioElement()
      ..preload = 'auto';
    final sources = [
      'assets/assets/sounds/new_order.wav',
      'assets/assets/sounds/new_order.ogg',
      'assets/assets/sounds/new_order.mp3',
    ];
    for (final src in sources) {
      _orderAudio!
        ..src = src
        ..volume = volume.clamp(0.0, 1.0);
      try {
        await _orderAudio!.play().toDart;
        return true;
      } catch (_) {
        continue;
      }
    }
  } catch (_) {}
  return false;
}

Future<void> _playBeep(String soundType, double volume) async {
  try {
    final ctx = web.AudioContext();
    if (ctx.state == 'suspended') {
      await ctx.resume().toDart;
    }
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    final freq = switch (soundType) {
      'security' => 880.0,
      'payments' => 740.0,
      'vendors' => 660.0,
      'stock' => 520.0,
      'delivery' => 590.0,
      _ => 440.0,
    };

    osc.frequency.value = freq;
    gain.gain.value = volume.clamp(0.0, 1.0) * 0.15;
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    osc.stop();
    ctx.close();
  } catch (_) {}
}
