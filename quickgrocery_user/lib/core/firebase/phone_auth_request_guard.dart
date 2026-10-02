import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Throttles OTP sends and persists cooldown across activity recreation.
class PhoneAuthRequestGuard {
  PhoneAuthRequestGuard();

  static const cooldownDuration = Duration(seconds: 60);
  static const tooManyRequestsCooldown = Duration(minutes: 3);
  static const minIntervalBetweenRequests = Duration(seconds: 2);

  static const _kCooldownUntilMs = 'phone_auth_cooldown_until_ms';
  static const _kLastPhone = 'phone_auth_last_phone';

  DateTime? _cooldownUntil;
  DateTime? _lastRequestAt;
  String? _lastPhoneE164;
  bool _requestInFlight = false;

  bool get isRequestInFlight => _requestInFlight;

  bool get isCooldownActive {
    final until = _cooldownUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  int get cooldownRemainingSeconds {
    final until = _cooldownUntil;
    if (until == null) return 0;
    final secs = until.difference(DateTime.now()).inSeconds;
    return secs < 0 ? 0 : secs;
  }

  String? get lastPhoneE164 => _lastPhoneE164;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kCooldownUntilMs);
    _lastPhoneE164 = prefs.getString(_kLastPhone);
    if (ms != null && ms > 0) {
      final until = DateTime.fromMillisecondsSinceEpoch(ms);
      if (DateTime.now().isBefore(until)) {
        _cooldownUntil = until;
      } else {
        _cooldownUntil = null;
        await prefs.remove(_kCooldownUntilMs);
      }
    }
  }

  Future<void> beginRequest(String phoneE164) async {
    _requestInFlight = true;
    _lastRequestAt = DateTime.now();
    _lastPhoneE164 = phoneE164;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastPhone, phoneE164);
  }

  void endRequest() {
    _requestInFlight = false;
  }

  /// Returns an error reason if a new OTP request must be blocked.
  String? blockReason({required String phoneE164}) {
    if (_requestInFlight) return 'in_flight';
    if (isCooldownActive) return 'cooldown';
    final last = _lastRequestAt;
    if (last != null &&
        DateTime.now().difference(last) < minIntervalBetweenRequests &&
        _lastPhoneE164 == phoneE164) {
      return 'too_fast';
    }
    return null;
  }

  Future<void> startCooldown({
    Duration duration = cooldownDuration,
  }) async {
    _cooldownUntil = DateTime.now().add(duration);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kCooldownUntilMs,
      _cooldownUntil!.millisecondsSinceEpoch,
    );
  }

  Future<void> startTooManyRequestsCooldown() =>
      startCooldown(duration: tooManyRequestsCooldown);

  Future<void> clearCooldown() async {
    _cooldownUntil = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCooldownUntilMs);
  }

  void logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[PhoneAuthGuard] $message');
    }
  }
}
