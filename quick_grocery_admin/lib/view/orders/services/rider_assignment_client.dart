import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class RankedRider {
  const RankedRider({
    required this.id,
    required this.name,
    required this.phone,
    required this.distanceKm,
    required this.workload,
    required this.online,
    required this.active,
    required this.eligible,
  });

  final String id;
  final String name;
  final String phone;
  final double distanceKm;
  final int workload;
  final bool online;
  final bool active;
  final bool eligible;

  factory RankedRider.fromMap(Map<String, dynamic> m) {
    return RankedRider(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? 'Rider',
      phone: m['phone']?.toString() ?? '',
      distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
      workload: (m['workload'] as num?)?.toInt() ?? 0,
      online: m['online'] == true,
      active: m['active'] == true,
      eligible: m['eligible'] == true,
    );
  }
}

class AutoAssignAllResult {
  const AutoAssignAllResult({
    required this.assigned,
    required this.attempted,
    required this.failures,
  });

  final int assigned;
  final int attempted;
  final List<String> failures;

  factory AutoAssignAllResult.fromMap(Map<String, dynamic> m) {
    return AutoAssignAllResult(
      assigned: (m['assigned'] as num?)?.toInt() ?? 0,
      attempted: (m['attempted'] as num?)?.toInt() ?? 0,
      failures: (m['failures'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}

/// Admin rider assignment via Cloud Functions (authoritative algorithm).
class RiderAssignmentClient {
  RiderAssignmentClient({FirebaseFunctions? functions})
      : _fn = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _fn;

  Future<void> assignRider({
    required String orderId,
    required String riderId,
    String? riderName,
    String? riderPhone,
  }) async {
    await _call('assignRiderCallable', {
      'orderId': orderId,
      'riderId': riderId,
      if (riderName != null) 'riderName': riderName,
      if (riderPhone != null) 'riderPhone': riderPhone,
    });
  }

  Future<({String riderId, String riderName, double distanceKm})> autoAssign(
    String orderId,
  ) async {
    final data = await _call('autoAssignRiderCallable', {'orderId': orderId});
    return (
      riderId: data['riderId']?.toString() ?? '',
      riderName: data['riderName']?.toString() ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<AutoAssignAllResult> autoAssignAll({int limit = 25}) async {
    final data = await _call('autoAssignAllUnassignedCallable', {
      'limit': limit,
    });
    return AutoAssignAllResult.fromMap(Map<String, dynamic>.from(data));
  }

  Future<({List<RankedRider> riders, double radiusKm})> rankRiders(
    String orderId,
  ) async {
    final data = await _call('rankRidersForOrderCallable', {
      'orderId': orderId,
    });
    final list = (data['riders'] as List?) ?? const [];
    return (
      riders: list
          .map((e) => RankedRider.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      radiusKm: (data['radiusKm'] as num?)?.toDouble() ?? 8,
    );
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    try {
      final result = await _fn.httpsCallable(name).call(payload);
      final data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'ok': true};
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) debugPrint('[RiderAssignment] $name: ${e.code} ${e.message}');
      rethrow;
    }
  }

  static String errorMessage(Object e) {
    if (e is FirebaseFunctionsException) {
      return e.message ?? 'Assignment failed';
    }
    return e.toString();
  }
}
