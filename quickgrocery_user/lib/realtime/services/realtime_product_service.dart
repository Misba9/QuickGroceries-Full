import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-only service exposing **realtime** views of the `products`
/// collection. Pure thin wrapper — no parsing, no UI side-effects.
///
/// Notes:
/// * Streams use `.snapshots()` so price / stock / image / offer changes
///   from the Admin or Vendor app appear in the User App without a
///   refresh.
/// * `whereIn` is capped to 30 doc-ids by Firestore — `watchByIds` shards
///   accordingly so callers can pass cart ids of any length.
class RealtimeProductService {
  RealtimeProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'products';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  /// Live single-product stream — used by product detail screens so
  /// price/stock/availability updates from Admin/Vendor flow live.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProduct(String id) {
    return _ref.doc(id).snapshots();
  }

  /// Live products in a category. The User App already streams these via
  /// `home_providers`; exposed here for non-home contexts (search, deep
  /// links, "more like this").
  Stream<QuerySnapshot<Map<String, dynamic>>> watchByCategory(
    String categoryId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> q =
        _ref.where('category', isEqualTo: categoryId);
    if (limit != null && limit > 0) q = q.limit(limit);
    return q.snapshots();
  }

  /// Live "low stock" alerts — useful for dashboard / inventory chips.
  /// Filters against `stock <= threshold`.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchLowStock({
    int threshold = 5,
    int limit = 50,
  }) {
    return _ref
        .where('stock', isLessThanOrEqualTo: threshold)
        .limit(limit)
        .snapshots();
  }

  /// Live multi-id stream — yields a merged snapshot for arbitrarily-large
  /// id lists by sharding into chunks of 30 (Firestore `whereIn` cap).
  ///
  /// Each shard re-emits independently; callers combine in the
  /// repository.
  Iterable<Stream<QuerySnapshot<Map<String, dynamic>>>> watchByIdsSharded(
    List<String> ids,
  ) sync* {
    if (ids.isEmpty) return;
    const max = 30;
    for (var i = 0; i < ids.length; i += max) {
      final shard = ids.sublist(i, i + max > ids.length ? ids.length : i + max);
      yield _ref
          .where(FieldPath.documentId, whereIn: shard)
          .snapshots();
    }
  }
}
