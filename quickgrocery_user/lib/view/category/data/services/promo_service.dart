import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore service for the `promos` collection (admin-driven media
/// slots rendered on the Categories discovery screen).
///
/// Filtering / ordering is intentionally done client-side so legacy
/// documents missing `isActive` / `priority` still surface — same
/// pattern as [HomeBannerService].
class PromoService {
  PromoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'promos';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActivePromos({int? limit}) {
    Query<Map<String, dynamic>> q = _ref;
    if (limit != null && limit > 0) q = q.limit(limit);
    return q.snapshots();
  }
}
