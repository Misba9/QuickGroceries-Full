import 'package:flutter/foundation.dart';

/// Hides the global floating cart while modals (e.g. notifications sheet) are open.
class FloatingCartSuppression {
  FloatingCartSuppression._();

  static int _depth = 0;

  static bool get isActive => _depth > 0;

  static final ValueNotifier<int> depthListenable = ValueNotifier(0);

  static void acquire() {
    _depth++;
    depthListenable.value = _depth;
  }

  static void release() {
    if (_depth > 0) _depth--;
    depthListenable.value = _depth;
  }

  /// Clears a stuck suppression counter (e.g. after a popped route failed to release).
  static void reset() {
    _depth = 0;
    depthListenable.value = 0;
  }
}
