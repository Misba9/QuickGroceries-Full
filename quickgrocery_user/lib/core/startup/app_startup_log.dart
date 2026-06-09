import 'dart:developer' as developer;

/// Timestamped startup milestones for performance tuning.
abstract final class AppStartupLog {
  static const bool enabled = true;

  static final Stopwatch _sw = Stopwatch();

  static void markAppStart() {
    if (!_sw.isRunning) _sw.start();
    milestone('App started');
  }

  static void milestone(String step, [String detail = '']) {
    if (!enabled) return;
    final ms = _sw.elapsedMilliseconds;
    final msg = detail.isEmpty ? '[$ms ms] $step' : '[$ms ms] $step · $detail';
    developer.log(msg, name: 'AppStartup');
  }

  static void log(String step, [String detail = '']) => milestone(step, detail);
}
