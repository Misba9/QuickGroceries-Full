import 'package:flutter/foundation.dart';

/// Structured checkout / order placement logs (debug & release logcat).
abstract final class OrderPlacementLog {
  static void buttonTapped({required String idempotencyKey}) {
    _log('button_tapped', 'key=$idempotencyKey');
  }

  static void duplicateTapIgnored({required String idempotencyKey}) {
    _log('duplicate_tap_ignored', 'key=$idempotencyKey');
  }

  static void loadingStarted({required String idempotencyKey}) {
    _log('loading_started', 'key=$idempotencyKey');
  }

  static void apiStarted({required String idempotencyKey, String? path}) {
    _log('api_started', 'key=$idempotencyKey path=${path ?? 'callable'}');
  }

  static void apiCompleted({
    required String idempotencyKey,
    required String orderId,
    bool duplicate = false,
  }) {
    _log(
      'api_completed',
      'key=$idempotencyKey orderId=$orderId duplicate=$duplicate',
    );
  }

  static void apiFailed({required String idempotencyKey, required Object error}) {
    _log('api_failed', 'key=$idempotencyKey error=$error');
  }

  static void navigationStarted({required String orderId}) {
    _log('navigation_started', 'orderId=$orderId');
  }

  static void navigationCompleted({required String orderId}) {
    _log('navigation_completed', 'orderId=$orderId');
  }

  static void navigationBlocked({required String reason}) {
    _log('navigation_blocked', reason);
  }

  static void _log(String event, String detail) {
    if (!kDebugMode) return;
    // Avoid logging order / payment identifiers outside debug builds.
    debugPrint('[OrderPlacement] $event');
  }
}
