import 'package:cloud_firestore/cloud_firestore.dart';

enum CodRestrictionType { none, temporary, permanent }

/// Per-customer COD eligibility — `customers/{uid}` payment restriction fields.
class CodPaymentRestriction {
  const CodPaymentRestriction({
    required this.codEnabled,
    required this.codRestrictionType,
    this.codRestrictionReason = '',
    this.codRestrictionNotes = '',
    this.codRestrictionStart,
    this.codRestrictionEnd,
    this.codRestrictedBy = '',
    this.codRestrictedByName = '',
    this.codUpdatedAt,
  });

  final bool codEnabled;
  final CodRestrictionType codRestrictionType;
  final String codRestrictionReason;
  final String codRestrictionNotes;
  final DateTime? codRestrictionStart;
  final DateTime? codRestrictionEnd;
  final String codRestrictedBy;
  final String codRestrictedByName;
  final DateTime? codUpdatedAt;

  static const enabled = CodPaymentRestriction(
    codEnabled: true,
    codRestrictionType: CodRestrictionType.none,
  );

  /// Effective UI badge after accounting for temporary expiry.
  CodRestrictionBadge get badge {
    if (codEnabled || codRestrictionType == CodRestrictionType.none) {
      return CodRestrictionBadge.enabled;
    }
    if (codRestrictionType == CodRestrictionType.temporary) {
      final end = codRestrictionEnd;
      if (end != null && !end.isAfter(DateTime.now())) {
        return CodRestrictionBadge.enabled;
      }
      return CodRestrictionBadge.temporary;
    }
    return CodRestrictionBadge.disabled;
  }

  bool get isRestrictedNow => badge != CodRestrictionBadge.enabled;

  factory CodPaymentRestriction.fromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return enabled;
    final type = _parseType(raw['codRestrictionType'] ?? raw['cod_restriction_type']);
    var enabled = true;
    if (raw['codEnabled'] is bool) {
      enabled = raw['codEnabled'] as bool;
    } else if (type == CodRestrictionType.temporary ||
        type == CodRestrictionType.permanent) {
      enabled = false;
    } else if (raw['codDisabled'] == true) {
      enabled = false;
    }
    return CodPaymentRestriction(
      codEnabled: enabled,
      codRestrictionType: type,
      codRestrictionReason:
          (raw['codRestrictionReason'] ?? raw['cod_restriction_reason'] ?? '')
              .toString(),
      codRestrictionNotes:
          (raw['codRestrictionNotes'] ?? raw['cod_restriction_notes'] ?? '')
              .toString(),
      codRestrictionStart: _ts(
        raw['codRestrictionStart'] ?? raw['cod_restriction_start'],
      ),
      codRestrictionEnd: _ts(
        raw['codRestrictionEnd'] ?? raw['cod_restriction_end'],
      ),
      codRestrictedBy:
          (raw['codRestrictedBy'] ?? raw['cod_restricted_by'] ?? '').toString(),
      codRestrictedByName:
          (raw['codRestrictedByName'] ?? raw['cod_restricted_by_name'] ?? '')
              .toString(),
      codUpdatedAt: _ts(raw['codUpdatedAt'] ?? raw['cod_updated_at']),
    );
  }

  Map<String, dynamic> toCallablePayload() => {
        'codRestrictionType': codRestrictionType.name,
        'codRestrictionReason': codRestrictionReason.trim(),
        'codRestrictionNotes': codRestrictionNotes.trim(),
        if (codRestrictionStart != null)
          'codRestrictionStart': codRestrictionStart!.toUtc().toIso8601String(),
        if (codRestrictionEnd != null)
          'codRestrictionEnd': codRestrictionEnd!.toUtc().toIso8601String(),
      };

  static CodRestrictionType _parseType(dynamic v) {
    final s = (v ?? 'none').toString().toLowerCase().trim();
    if (s == 'temporary') return CodRestrictionType.temporary;
    if (s == 'permanent') return CodRestrictionType.permanent;
    return CodRestrictionType.none;
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

enum CodRestrictionBadge { enabled, disabled, temporary }

extension CodRestrictionBadgeX on CodRestrictionBadge {
  String get label => switch (this) {
        CodRestrictionBadge.enabled => 'COD Enabled',
        CodRestrictionBadge.disabled => 'COD Disabled',
        CodRestrictionBadge.temporary => 'Temporary Restriction',
      };

  String get emoji => switch (this) {
        CodRestrictionBadge.enabled => '✅',
        CodRestrictionBadge.disabled => '🚫',
        CodRestrictionBadge.temporary => '⏳',
      };
}

class CodRestrictionHistoryEntry {
  const CodRestrictionHistoryEntry({
    required this.id,
    required this.adminName,
    required this.action,
    required this.reason,
    this.oldStatus,
    this.newStatus,
    this.createdAt,
  });

  final String id;
  final String adminName;
  final String action;
  final String reason;
  final Map<String, dynamic>? oldStatus;
  final Map<String, dynamic>? newStatus;
  final DateTime? createdAt;

  factory CodRestrictionHistoryEntry.fromMap(
    Map<String, dynamic> raw,
    String id,
  ) {
    return CodRestrictionHistoryEntry(
      id: id,
      adminName: (raw['adminName'] ?? '').toString(),
      action: (raw['action'] ?? '').toString(),
      reason: (raw['reason'] ?? '').toString(),
      oldStatus: raw['oldStatus'] is Map
          ? Map<String, dynamic>.from(raw['oldStatus'] as Map)
          : null,
      newStatus: raw['newStatus'] is Map
          ? Map<String, dynamic>.from(raw['newStatus'] as Map)
          : null,
      createdAt: CodPaymentRestriction._ts(raw['createdAt']),
    );
  }
}
