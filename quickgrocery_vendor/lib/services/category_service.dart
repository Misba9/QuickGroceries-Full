import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

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
  Future<List<CategoryModel>> getSubcategoriesByCategoryId(
    String categoryId,
  ) async {
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
  Future<List<CategoryModel>> getSubcategoriesByCategory(
    String categoryName,
  ) async {
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

  /// Stream all subcategories (for real-time updates)
  Stream<List<CategoryModel>> getSubcategoriesStream() {
    return _firestore
        .collection('subcategories')
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream subcategories for a specific category by category ID
  Stream<List<CategoryModel>> getSubcategoriesByCategoryIdStream(
    String categoryId,
  ) {
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
  Stream<List<CategoryModel>> getSubcategoriesByCategoryStream(
    String categoryName,
  ) {
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

  Future<Uint8List?> pickImageBytes() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  Future<String> uploadCategoryImage(Uint8List imageData) async {
    final ref = FirebaseStorage.instance.ref().child(
      'shop_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putData(imageData);
    return ref.getDownloadURL();
  }

  Future<CategoryModel> addCategory({
    required String name,
    required int order,
    required Uint8List imageBytes,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    final imageUrl = await uploadCategoryImage(imageBytes);
    final docRef = await _firestore.collection('categories').add({
      'id': '',
      'name': trimmed,
      'image': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'order': order,
      'isActive': true,
    });
    await docRef.update({'id': docRef.id});

    return CategoryModel(
      id: docRef.id,
      name: trimmed,
      image: imageUrl,
      createdAt: Timestamp.now(),
      order: order,
    );
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required int order,
    Uint8List? imageBytes,
    String? existingImage,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    final updateData = <String, dynamic>{
      'name': trimmed,
      'order': order,
    };

    if (imageBytes != null) {
      updateData['image'] = await uploadCategoryImage(imageBytes);
    } else if (existingImage != null && existingImage.isNotEmpty) {
      updateData['image'] = existingImage;
    }

    await _firestore.collection('categories').doc(id).update(updateData);
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  Future<CategoryModel> addSubCategory({
    required String name,
    required int order,
    required String mainCategoryName,
    required Uint8List imageBytes,
  }) async {
    final trimmed = name.trim();
    final main = mainCategoryName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Subcategory name cannot be empty');
    }
    if (main.isEmpty) {
      throw Exception('Please select a main category');
    }

    final imageUrl = await uploadCategoryImage(imageBytes);
    final docRef = await _firestore.collection('subcategories').add({
      'id': '',
      'name': trimmed,
      'image': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'order': order,
      'main_category': main,
      'isActive': true,
    });
    await docRef.update({'id': docRef.id});

    return CategoryModel(
      id: docRef.id,
      name: trimmed,
      image: imageUrl,
      createdAt: Timestamp.now(),
      order: order,
      mainCategory: main,
    );
  }

  Future<void> updateSubCategory({
    required String id,
    required String name,
    required int order,
    required String mainCategoryName,
    Uint8List? imageBytes,
    String? existingImage,
  }) async {
    final trimmed = name.trim();
    final main = mainCategoryName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Subcategory name cannot be empty');
    }
    if (main.isEmpty) {
      throw Exception('Please select a main category');
    }

    final updateData = <String, dynamic>{
      'name': trimmed,
      'order': order,
      'main_category': main,
    };

    if (imageBytes != null) {
      updateData['image'] = await uploadCategoryImage(imageBytes);
    } else if (existingImage != null && existingImage.isNotEmpty) {
      updateData['image'] = existingImage;
    }

    await _firestore.collection('subcategories').doc(id).update(updateData);
  }

  Future<void> deleteSubCategory(String id) async {
    await _firestore.collection('subcategories').doc(id).delete();
  }
}
