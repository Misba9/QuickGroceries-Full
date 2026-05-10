import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore service for the `categories` collection.
///
/// Pure I/O — no caching, no business rules, no UI types. The repository
/// layer is responsible for mapping the raw snapshots into domain models
/// and for any error normalization.
class HomeCategoryService {
  HomeCategoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'categories';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  /// Realtime stream of active categories ordered by `order` ascending.
  ///
  /// Falls back to client-side filtering of `isActive` so legacy documents
  /// (which may not have the field) still surface in the UI.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveCategories({
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _ref.orderBy('order');
    if (limit != null && limit > 0) query = query.limit(limit);
    return query.snapshots();
  }

  /// One-shot fetch — useful for explicit pull-to-refresh.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchActiveCategories({
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _ref.orderBy('order');
    if (limit != null && limit > 0) query = query.limit(limit);
    return query.get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchById(String id) {
    return _ref.doc(id).get();
  }
}
