import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String image;
  final Timestamp createdAt;
  final int order;
  final String? mainCategory; // For subcategories

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.createdAt,
    required this.order,
    this.mainCategory,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      order: data['order'] ?? 0,
      mainCategory: data['main_category'],
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? json['createdAt']
          : Timestamp.now(),
      order: json['order'] is int ? json['order'] : (json['order'] is String ? int.tryParse(json['order']) ?? 0 : 0),
      mainCategory: json['main_category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "name": name,
      "image": image,
      "createdAt": FieldValue.serverTimestamp(),
      "order": order,
      if (mainCategory != null) "main_category": mainCategory,
    };
  }
}
