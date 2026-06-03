import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quick_grocery_admin/view/delivery_tips/models/delivery_tips_settings_model.dart';

class DeliveryTipsAdminService {
  DeliveryTipsAdminService({FirebaseFirestore? firestore, FirebaseFunctions? fn})
      : _db = firestore ?? FirebaseFirestore.instance,
        _fn = fn ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  Stream<DeliveryTipsSettingsModel> watchSettings() {
    return _db.doc('app_settings/delivery_tips').snapshots().map((s) {
      return DeliveryTipsSettingsModel.fromMap(s.data());
    });
  }

  Future<void> saveSettings(DeliveryTipsSettingsModel model) async {
    final callable = _fn.httpsCallable('adminDeliveryTipsCallable');
    await callable.call({
      'action': 'save_settings',
      ...model.toCallablePayload(),
    });
  }

  Future<DeliveryTipsDashboardStats> aggregateStats({int days = 30}) async {
    final res = await _fn.httpsCallable('adminDeliveryTipsCallable').call({
      'action': 'aggregate_stats',
      'days': days,
    });
    final data = res.data as Map<String, dynamic>? ?? {};
    final byDateRaw = data['tipsByDate'] as List? ?? [];
    final tipsByDate = <MapEntry<String, double>>[];
    for (final row in byDateRaw) {
      if (row is Map) {
        tipsByDate.add(MapEntry(
          '${row['date']}',
          (row['amount'] as num?)?.toDouble() ?? 0,
        ));
      }
    }
    return DeliveryTipsDashboardStats(
      totalTipsCollected: (data['totalTipsCollected'] as num?)?.toDouble() ?? 0,
      tipsByDate: tipsByDate,
      topRiders: List<Map<String, dynamic>>.from(
        (data['topRiders'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ??
            [],
      ),
      orderCount: (data['orderCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<DeliveryTipReportRow>> fetchReportRows({int limit = 100}) async {
    final res = await _fn.httpsCallable('adminDeliveryTipsCallable').call({
      'action': 'list_tip_orders',
      'limit': limit,
    });
    final rows = res.data is Map ? res.data['rows'] as List? : null;
    if (rows == null) return [];
    return rows
        .map((e) => DeliveryTipReportRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
