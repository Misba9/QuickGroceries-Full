import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all categories (main categories)
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all subcategories
  Future<List<CategoryModel>> getSubcategories() async {
    try {
      final snapshot = await _firestore
          .collection('subcategories')
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get subcategories for a specific category by category ID
  Future<List<CategoryModel>> getSubcategoriesByCategoryId(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('subcategories')
          .where('main_category', isEqualTo: categoryId)
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get subcategories for a specific category by category name
  /// This method uses the main_category field which stores the category name
  Future<List<CategoryModel>> getSubcategoriesByCategory(String categoryName) async {
    try {
      final snapshot = await _firestore
          .collection('subcategories')
          .where('main_category', isEqualTo: categoryName)
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream all categories (for real-time updates)
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection('categories')
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream subcategories for a specific category by category ID
  Stream<List<CategoryModel>> getSubcategoriesByCategoryIdStream(String categoryId) {
    return _firestore
        .collection('subcategories')
        .where('main_category', isEqualTo: categoryId)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream subcategories for a specific category by category name
  /// This method uses the main_category field which stores the category name
  Stream<List<CategoryModel>> getSubcategoriesByCategoryStream(String categoryName) {
    return _firestore
        .collection('subcategories')
        .where('main_category', isEqualTo: categoryName)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
}

