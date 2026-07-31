import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/view/search_analytics/models/search_log_model.dart';

class SearchAnalyticsService {
  SearchAnalyticsService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;
  static const collection = 'search_logs';

  /// Live feed via Cloud Function (rules-safe). Polls every 12s.
  Stream<List<SearchLogModel>> watchLogs({int limit = 500}) {
    final controller = StreamController<List<SearchLogModel>>();
    Timer? timer;
    var cancelled = false;

    Future<void> pull() async {
      try {
        final logs = await fetchLogsViaCallable(limit: limit);
        if (!cancelled && !controller.isClosed) {
          controller.add(logs);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[SearchAnalytics] callable list: $e');
        // Last-resort Firestore read (often denied by rules).
        try {
          final snap = await _db
              .collection(collection)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();
          final logs =
              snap.docs.map(SearchLogModel.fromDoc).toList(growable: false);
          if (!cancelled && !controller.isClosed) controller.add(logs);
        } catch (e2) {
          if (kDebugMode) debugPrint('[SearchAnalytics] firestore get: $e2');
          if (!cancelled && !controller.isClosed) {
            controller.add(const []);
          }
        }
      }
    }

    controller.onListen = () {
      unawaited(pull());
      timer = Timer.periodic(const Duration(seconds: 12), (_) => pull());
    };
    controller.onCancel = () {
      cancelled = true;
      timer?.cancel();
    };

    return controller.stream;
  }

  Stream<List<SearchLogModel>> watchLogsFallback({int limit = 500}) =>
      watchLogs(limit: limit);

  Future<List<SearchLogModel>> fetchLogsViaCallable({int limit = 500}) async {
    final res = await _fn.httpsCallable('listSearchLogsCallable').call({
      'limit': limit,
    });
    final data = res.data;
    if (data is! Map) return const [];
    final raw = data['logs'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => SearchLogModel.fromMap(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Map<String, dynamic> kpis(List<SearchLogModel> logs) {
    final uniqueQueries = <String>{};
    final uniqueUsers = <String>{};
    var zero = 0;
    for (final e in logs) {
      if (e.queryNormalized.isNotEmpty) uniqueQueries.add(e.queryNormalized);
      if (e.userId.isNotEmpty) uniqueUsers.add(e.userId);
      if (!e.hasResults) zero++;
    }
    return {
      'total': logs.length,
      'uniqueQueries': uniqueQueries.length,
      'uniqueUsers': uniqueUsers.length,
      'zeroResults': zero,
      'zeroRate': logs.isEmpty ? 0.0 : (zero / logs.length) * 100,
    };
  }

  List<SearchQueryAggregate> aggregateQueries(List<SearchLogModel> logs) {
    final map = <String, SearchQueryAggregate>{};
    for (final e in logs) {
      final key = e.queryNormalized.isEmpty
          ? e.query.toLowerCase().trim()
          : e.queryNormalized;
      if (key.isEmpty) continue;
      final agg = map.putIfAbsent(
        key,
        () => SearchQueryAggregate(query: e.query, queryNormalized: key),
      );
      agg.count++;
      if (!e.hasResults) agg.zeroResultCount++;
      if (e.userId.isNotEmpty) agg.userIds.add(e.userId);
      if (e.createdAt != null &&
          (agg.lastSearchedAt == null ||
              e.createdAt!.isAfter(agg.lastSearchedAt!))) {
        agg.lastSearchedAt = e.createdAt;
        agg.lastPlatform = e.platform;
        if (e.query.isNotEmpty) agg.query = e.query;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  Future<Map<String, String>> resolveCustomerLabels(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    final out = <String, String>{};
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snaps = await Future.wait(
        chunk.map((id) => _db.collection('customers').doc(id).get()),
      );
      for (final snap in snaps) {
        if (!snap.exists) continue;
        final data = snap.data() ?? {};
        final name =
            (data['name'] ?? data['fullName'] ?? data['displayName'] ?? '')
                .toString()
                .trim();
        final phone =
            (data['phone'] ?? data['phoneNumber'] ?? '').toString().trim();
        final label =
            name.isNotEmpty ? name : (phone.isNotEmpty ? phone : snap.id);
        out[snap.id] = label;
      }
    }
    return out;
  }
}
