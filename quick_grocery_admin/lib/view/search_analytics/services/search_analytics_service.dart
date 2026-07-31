import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/view/search_analytics/models/search_log_model.dart';

class SearchAnalyticsService {
  SearchAnalyticsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const collection = 'search_logs';

  /// Recent raw search events (newest first).
  Stream<List<SearchLogModel>> watchLogs({int limit = 500}) {
    return _db
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(SearchLogModel.fromDoc).toList(growable: false),
        );
  }

  /// Fallback when `createdAt` ordering fails — client sorts by timestamp.
  Stream<List<SearchLogModel>> watchLogsFallback({int limit = 500}) {
    return _db.collection(collection).limit(limit).snapshots().map((snap) {
      final list = snap.docs.map(SearchLogModel.fromDoc).toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
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

  /// Enrich blank user names from `customers/{uid}` when possible.
  Future<Map<String, String>> resolveCustomerLabels(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
    final out = <String, String>{};
    // Firestore getAll is limited; batch in chunks of 10 via parallel gets.
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snaps = await Future.wait(
        chunk.map((id) => _db.collection('customers').doc(id).get()),
      );
      for (final snap in snaps) {
        if (!snap.exists) continue;
        final data = snap.data() ?? {};
        final name = (data['name'] ?? data['fullName'] ?? data['displayName'] ?? '')
            .toString()
            .trim();
        final phone =
            (data['phone'] ?? data['phoneNumber'] ?? '').toString().trim();
        final label = name.isNotEmpty
            ? name
            : (phone.isNotEmpty ? phone : snap.id);
        out[snap.id] = label;
      }
    }
    return out;
  }
}
