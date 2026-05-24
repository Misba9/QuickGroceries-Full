import 'package:web/web.dart' as web;

/// Short beep via Web Audio — works in Chrome admin panel without asset files.
Future<void> playPlatformAlert(String soundType, {double volume = 1.0}) async {
  try {
    final ctx = web.AudioContext();
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
