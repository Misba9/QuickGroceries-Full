import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin Firestore service for the `ratings` collection.
class ProductRatingService {
  ProductRatingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'ratings';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  /// Realtime list of ratings for a product, newest first.
  ///
  /// We avoid a server-side `orderBy('created_at')` here because legacy
  /// rating documents may be missing the field; sorting happens in the
  /// repository so partial data still surfaces.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRatings(
    String productId, {
    int limit = 50,
  }) {
    return _ref
        .where('product_id', isEqualTo: productId)
        .limit(limit)
        .snapshots();
  }
}
