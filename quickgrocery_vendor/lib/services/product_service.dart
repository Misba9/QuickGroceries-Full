import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'products';

  /// Get all products for a specific vendor
  Stream<List<ProductModel>> getVendorProducts(String vendorId) {
    return _firestore
        .collection(_collectionName)
        .where('vendor_id', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get a single product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Add a new product
  Future<String> addProduct(ProductModel product) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(product.id)
          .update(product.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collectionName).doc(productId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle product active status
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(productId)
          .update({
        'is_active': isActive,
        'lastEdited': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}

