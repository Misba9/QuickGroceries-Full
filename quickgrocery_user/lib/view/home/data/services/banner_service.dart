import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore service for the `banners` collection.
class HomeBannerService {
  HomeBannerService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'banners';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  /// Realtime stream of all banners. Filtering (`isActive`) and ordering
  /// (`priority`) are applied client-side in [BannerRepository].
  ///
  /// Why no server-side `orderBy('priority')` or `where('isActive')`:
  /// Firestore silently excludes documents missing the field used in
  /// `orderBy`/`where`, so legacy banner docs created without these fields
  /// would never reach the client. By keeping the query unfiltered we let
  /// every banner show up, then apply defaults (`isActive=true`,
  /// `priority=0`) in the model.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveBanners({
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _ref;
    if (limit != null && limit > 0) query = query.limit(limit);
    return query.snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchActiveBanners({
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _ref;
    if (limit != null && limit > 0) query = query.limit(limit);
    return query.get(const GetOptions(source: Source.serverAndCache));
  }
}
