import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:quick_grocery_admin/model/cod_payment_restriction.dart';

/// Admin APIs for per-user COD payment restrictions.
class CodRestrictionAdminService {
  CodRestrictionAdminService({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _fn;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<T> _call<T>(String name, Map<String, dynamic> payload) async {
    final result = await _fn.httpsCallable(name).call(payload);
    return result.data as T;
  }

  Future<({CodPaymentRestriction restriction, List<CodRestrictionHistoryEntry> history})>
      getForUser(String userId) async {
    final data = await _call<Map<dynamic, dynamic>>(
      'getCustomerPaymentRestrictionsCallable',
      {'userId': userId},
    );
    final pr = data['paymentRestrictions'];
    final restriction = CodPaymentRestriction.fromMap(
      pr is Map ? Map<String, dynamic>.from(pr) : null,
    );
    final historyRaw = data['history'];
    final history = <CodRestrictionHistoryEntry>[];
    if (historyRaw is List) {
      for (final e in historyRaw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          history.add(
            CodRestrictionHistoryEntry.fromMap(m, (m['id'] ?? '').toString()),
          );
        }
      }
    }
    return (restriction: restriction, history: history);
  }

  Future<CodPaymentRestriction> updateForUser({
    required String userId,
    required CodRestrictionType type,
    String reason = '',
    String notes = '',
    DateTime? start,
    DateTime? end,
  }) async {
    final payload = <String, dynamic>{
      'userId': userId,
      'codRestrictionType': type.name,
      'codRestrictionReason': reason,
      'codRestrictionNotes': notes,
      if (start != null) 'codRestrictionStart': start.toUtc().toIso8601String(),
      if (end != null) 'codRestrictionEnd': end.toUtc().toIso8601String(),
    };
    final data = await _call<Map<dynamic, dynamic>>(
      'updateCustomerPaymentRestrictionsCallable',
      payload,
    );
    final pr = data['paymentRestrictions'];
    return CodPaymentRestriction.fromMap(
      pr is Map ? Map<String, dynamic>.from(pr) : null,
    );
  }

  Future<CodPaymentRestriction> removeForUser(String userId, {String? reason}) async {
    final data = await _call<Map<dynamic, dynamic>>(
      'deleteCustomerPaymentRestrictionsCallable',
      {
        'userId': userId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final pr = data['paymentRestrictions'];
    return CodPaymentRestriction.fromMap(
      pr is Map ? Map<String, dynamic>.from(pr) : null,
    );
  }

  /// Browse restricted users. Prefer callable; fallback Firestore query.
  Future<List<CodRestrictedCustomerRow>> listRestricted() async {
    try {
      final data = await _call<Map<dynamic, dynamic>>(
        'listCodRestrictedCustomersCallable',
        {'limit': 150},
      );
      final items = data['items'];
      final rows = <CodRestrictedCustomerRow>[];
      if (items is List) {
        for (final e in items) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final pr = m['paymentRestrictions'];
          rows.add(
            CodRestrictedCustomerRow(
              userId: (m['userId'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
              phone: (m['phone'] ?? '').toString(),
              email: (m['email'] ?? '').toString(),
              restriction: CodPaymentRestriction.fromMap(
                pr is Map ? Map<String, dynamic>.from(pr) : null,
              ),
            ),
          );
        }
      }
      return rows;
    } catch (e) {
      if (kDebugMode) debugPrint('listCodRestrictedCustomersCallable: $e');
      return _listRestrictedFromFirestore();
    }
  }

  Future<List<CodRestrictedCustomerRow>> _listRestrictedFromFirestore() async {
    final snap = await _db
        .collection('customers')
        .where('codEnabled', isEqualTo: false)
        .limit(150)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return CodRestrictedCustomerRow(
        userId: d.id,
        name: (data['name'] ?? '').toString(),
        phone: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        restriction: CodPaymentRestriction.fromMap(data),
      );
    }).where((r) => r.restriction.isRestrictedNow).toList();
  }
}

class CodRestrictedCustomerRow {
  const CodRestrictedCustomerRow({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.restriction,
  });

  final String userId;
  final String name;
  final String phone;
  final String email;
  final CodPaymentRestriction restriction;
}
