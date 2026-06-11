import 'dart:math';

/// One key per checkout session — reused for duplicate taps and retries.
abstract final class OrderIdempotency {
  static final _random = Random.secure();

  static String generateKey() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final a = _random.nextInt(0x7fffffff);
    final b = _random.nextInt(0x7fffffff);
    return '$ts-$a-$b';
  }
}
