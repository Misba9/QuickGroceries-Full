import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin Firestore service for the product details screen.
///
/// Pure I/O — no domain mapping, no caching. The repository layer wraps
/// these streams into typed models and normalizes errors.
class ProductDetailService {
  ProductDetailService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _collection = 'products';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  /// Realtime document for a single product. Lets us reflect price /
  /// stock / availability / rating updates without a manual reload.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProduct(String id) {
    return _ref.doc(id).snapshots();
  }

  /// One-shot fetch — used as a fallback when the stream is rebuilt.
  Future<DocumentSnapshot<Map<String, dynamic>>> fetchProduct(String id) {
    return _ref.doc(id).get();
  }

  /// Similar products by category, excluding the current product id.
  /// We `limit` server-side to keep the read cost bounded.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchSimilarProducts({
    required String category,
    required String excludeId,
    int limit = 10,
  }) {
    // Firestore can't filter `!=` together with other constraints
    // efficiently, so the exclusion is applied client-side after fetch.
    return _ref
        .where('category', isEqualTo: category)
        .limit(limit + 1)
        .snapshots();
  }

  /// Fetch products for a list of ids — used by the recently-viewed rail.
  /// `whereIn` accepts up to 30 values per call (Firestore limit).
  Future<QuerySnapshot<Map<String, dynamic>>> fetchProductsByIds(
    List<String> ids,
  ) {
    if (ids.isEmpty) {
      // Empty `whereIn` throws; short-circuit with a query that yields none.
      return _ref.where(FieldPath.documentId, isEqualTo: '__none__').get();
    }
    final clamped = ids.length > 30 ? ids.sublist(0, 30) : ids;
    return _ref.where(FieldPath.documentId, whereIn: clamped).get();
  }

  // ── Favorites (uses the existing `is_favorite` array field) ────────────
  String? get _uid => _auth.currentUser?.uid;

  Future<void> addToFavorites(String productId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign-in required to favorite a product.');
    }
    await _ref.doc(productId).update({
      'is_favorite': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> removeFromFavorites(String productId) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign-in required to update favorites.');
    }
    await _ref.doc(productId).update({
      'is_favorite': FieldValue.arrayRemove([uid]),
    });
  }
}
