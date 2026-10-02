import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-side view of per-user COD eligibility from `customers/{uid}`.
class CodEligibility {
  const CodEligibility({
    required this.codEnabled,
    required this.restrictionType,
    this.reason = '',
    this.message = '',
    this.end,
  });

  final bool codEnabled;
  final String restrictionType; // none | temporary | permanent
  final String reason;
  final String message;
  final DateTime? end;

  static const allowed = CodEligibility(
    codEnabled: true,
    restrictionType: 'none',
  );

  /// Effective eligibility after temporary auto-expiry.
  bool get isCodAllowed {
    if (codEnabled || restrictionType == 'none') return true;
    if (restrictionType == 'temporary') {
      final e = end;
      if (e != null && !e.isAfter(DateTime.now())) return true;
    }
    return false;
  }

  String get blockedMessage => message.isNotEmpty
      ? message
      : 'Cash on Delivery is unavailable for your account. Please use Online Payment.';

  factory CodEligibility.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return allowed;

    final type =
        (raw['codRestrictionType'] ?? raw['cod_restriction_type'] ?? 'none')
            .toString()
            .toLowerCase()
            .trim();
    var enabled = true;
    if (raw['codEnabled'] is bool) {
      enabled = raw['codEnabled'] as bool;
    } else if (type == 'temporary' || type == 'permanent') {
      enabled = false;
    } else if (raw['codDisabled'] == true) {
      enabled = false;
    }

    return CodEligibility(
      codEnabled: enabled,
      restrictionType: type.isEmpty ? 'none' : type,
      reason: (raw['codRestrictionReason'] ?? '').toString(),
      message: (raw['message'] ?? '').toString(),
      end: _toDate(raw['codRestrictionEnd'] ?? raw['cod_restriction_end']),
    );
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}
